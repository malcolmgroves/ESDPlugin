{
  * Simple WebSocket client for Delphi
  * http://www.websocket.org/echo.html
  * Author: Lucas Rubian Schatz
  * Copyright 2018, Indy Working Group.
  *
  * Date: 25/05/2019 - Jason R. Nelson (adaloveless) - Fix warning and incorrect URI in "GET" request
  * Date: 22/02/2018
  TODO: implement methods for sending and receiving binary data, and support for bigger than 65536 bytes support
}

unit IdWebSocketSimpleClient;

interface

uses Classes, System.SysUtils, IdSSLOpenSSL, IdTCPClient, IdGlobal, IdCoderMIME,
	IdHash, IdHashSHA, Math, System.Threading, DateUtils, System.SyncObjs,
	IdURI;

Type
	TSWSCDataEvent = procedure(Sender: TObject; const Text: String) of object;
	TSWSCErrorEvent = procedure(Sender: TObject; Exception: Exception; const Text: String; var ForceDisconnect) of object;
	// *  %x0 denotes a continuation frame
	// *  %x1 denotes a text frame
	// *  %x2 denotes a binary frame
	// *  %x3-7 are reserved for further non-control frames
	// *  %x8 denotes a connection close
	// *  %x9 denotes a ping
	// *  %xA denotes a pong
	// *  %xB-F are reserved for further control frames

	TOpCode = (TOContinuation, TOTextFrame, TOBinaryFrame, TOConnectionClose, TOPing, TOPong);

Const
	TOpCodeByte: array [TOpCode] of Byte = ($0, $1, $2, $8, $9, $A);

Type
	TIdSimpleWebSocketClient = class(TIdTCPClient)
	private
		SecWebSocketAcceptExpectedResponse: String;
		FHeartBeatInterval: Cardinal;
		FAutoCreateHandler: Boolean;
		FURL: String;
		FOnUpgrade: TNotifyEvent;
		FOnHeartBeatTimer: TNotifyEvent;
		FOnError: TSWSCErrorEvent;
		FOnPing: TSWSCDataEvent;
		FOnConnectionDataEvent: TSWSCDataEvent;
		FOnAfterConnectionDataEvent: TSWSCDataEvent;
		FOnDataEvent: TSWSCDataEvent;
		FUpgraded: Boolean;

	protected
		lInternalLock: TCriticalSection;
		lClosingEventLocalHandshake: Boolean;

		// Sync Event
		lSyncFunctionEvent:		TSimpleEvent;
		lSyncFunctionTrigger:	TFunc<String, Boolean>;
		// Sync Event

		// get if a particular bit is 1
		function	Get_a_Bit(const aValue: Cardinal; const Bit: Byte): Boolean;
		// set a particular bit as 1
		function	Set_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
		// set a particular bit as 0
		function	Clear_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;

		procedure	ReadFromWebSocket; virtual;
		function	EncodeFrame(Msg: String; OpCode: TOpCode = TOpCode.TOTextFrame): TIdBytes;
		function	VerifyHeader(Header: TStrings): Boolean;
		procedure	StartHeartBeat;
		procedure	SendCloseHandshake;
		function	GenerateWebSocketKey: String;

	published
		property OnDataEvent: TSWSCDataEvent read FOnDataEvent write FOnDataEvent;
		property OnConnectionDataEvent: TSWSCDataEvent read FOnConnectionDataEvent write FOnConnectionDataEvent;
		property OnAfterConnectionDataEvent: TSWSCDataEvent read FOnAfterConnectionDataEvent write FOnAfterConnectionDataEvent;
		property OnPing: TSWSCDataEvent read FOnPing write FOnPing;
		property OnError: TSWSCErrorEvent read FOnError write FOnError;
		property OnHeartBeatTimer: TNotifyEvent read FOnHeartBeatTimer write FOnHeartBeatTimer;
		property OnUpgrade: TNotifyEvent read FOnUpgrade write FOnUpgrade;
		property HeartBeatInterval: Cardinal read FHeartBeatInterval write FHeartBeatInterval;
		property AutoCreateHandler: Boolean read FAutoCreateHandler write FAutoCreateHandler;
		property URL: String read FURL write FURL;

	public
		procedure	Connect(URL: String); overload;
		procedure	Close;
		function	Connected:	Boolean; reintroduce; overload;
		property	Upgraded:	Boolean read FUpgraded;

		procedure	WriteText(Msg: String);
		procedure	WriteTextSync(Msg: String; pTriggerFunction: TFunc<String, Boolean>);

		constructor	Create(AOwner: TComponent);
		destructor	Destroy; override;
	end;

//*************************************************************//

implementation

{ TIdSimpleWebSocketClient }

//*************************************************************//

function TIdSimpleWebSocketClient.Clear_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
	Result := aValue and not(1 shl Bit);
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.Close;
begin
    Self.lInternalLock.Enter;
    try
        if Self.Connected then
            begin
            Self.SendCloseHandshake;
            Self.IOHandler.InputBuffer.Clear;
            Self.IOHandler.CloseGracefully;
            Self.Disconnect;
            if assigned(Self.OnDisconnected) then
                Self.OnDisconnected(Self);
            end;
    finally
        Self.lInternalLock.Leave;
end
end;

//*************************************************************//

function TIdSimpleWebSocketClient.GenerateWebSocketKey(): String;
var
	rand: TIdBytes;
	I: Integer;
begin
    SetLength(rand, 16);
    for I := low(rand) to High(rand) do
        rand[I] := Byte(random(255));

    Result := TIdEncoderMIME.EncodeBytes(rand); // generates a random Base64String
    Self.SecWebSocketAcceptExpectedResponse := Result + '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
    // fixed String, see: https://tools.ietf.org/html/rfc6455#section-1.3

    with TIdHashSHA1.Create do
        try
            SecWebSocketAcceptExpectedResponse := TIdEncoderMIME.EncodeBytes
              (HashString(Self.SecWebSocketAcceptExpectedResponse));
        finally
            Free;
        end;
end;

//*************************************************************//

function TIdSimpleWebSocketClient.Connected: Boolean;
begin
    Result := false;
    // for some reason, if its not connected raises an error after connection lost!
    try
        Result := inherited;
    except
    end
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.Connect(URL: String);
var
	URI: TIdURI;
	lSecure: Boolean;
begin
    URI := nil;
    try
        lClosingEventLocalHandshake := false;
        URI := TIdURI.Create(URL);
        Self.URL := URL;
        Self.Host := URI.Host;
        URI.Protocol := ReplaceOnlyFirst(URI.Protocol.ToLower, 'ws', 'http');
        // replaces wss to https too, as apparently indy does not support ws(s) yet

        if URI.Path = '' then
            URI.Path := '/';
        lSecure := URI.Protocol = 'https';

        if URI.Port.IsEmpty then
            begin
            if lSecure then
                Self.Port := 443
            else
                Self.Port := 80;
            end
        else
            Self.Port := StrToInt(URI.Port);

        if lSecure and (Self.IOHandler = nil) then
            begin
            if Self.AutoCreateHandler then // for simple life
                begin
                Self.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Self);
                (Self.IOHandler as TIdSSLIOHandlerSocketOpenSSL).SSLOptions.Mode :=
                  TIdSSLMode.sslmClient;
                (Self.IOHandler as TIdSSLIOHandlerSocketOpenSSL)
                  .SSLOptions.SSLVersions := [TIdSSLVersion.sslvTLSv1,
                  TIdSSLVersion.sslvTLSv1_1, TIdSSLVersion.sslvTLSv1_2];
                // depending on your server, change this at your code;
                end
            else
                raise exception.Create
                  ('Please, inform a TIdSSLIOHandlerSocketOpenSSL descendant');
            end;

        if Self.Connected then
            raise exception.Create('Already connected, verify');

        inherited Connect;
        if not URI.Port.IsEmpty then
            URI.Host := URI.Host + ':' + URI.Port;
        Self.Socket.WriteLn(format('GET %s HTTP/1.1', [URI.Path + URI.Document]));
        Self.Socket.WriteLn(format('Host: %s', [URI.Host]));
        Self.Socket.WriteLn('User-Agent: Delphi WebSocket Simple Client');
        Self.Socket.WriteLn('Connection: keep-alive, Upgrade');
        Self.Socket.WriteLn('Upgrade: WebSocket');
        Self.Socket.WriteLn('Sec-WebSocket-Version: 13');
        Self.Socket.WriteLn(format('Sec-WebSocket-Key: %s', [GenerateWebSocketKey()]));
        Self.Socket.WriteLn('');

        ReadFromWebSocket;
        StartHeartBeat;
    finally
        URI.Free;
    end;
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.SendCloseHandshake;
begin
    Self.lClosingEventLocalHandshake := true;
    Self.Socket.Write(Self.EncodeFrame('', TOpCode.TOConnectionClose));
    TThread.Sleep(200);
end;

//*************************************************************//

constructor TIdSimpleWebSocketClient.Create(AOwner: TComponent);
begin
    inherited;
    lInternalLock := TCriticalSection.Create;
    Randomize;
    Self.AutoCreateHandler := false;
    Self.HeartBeatInterval := 30000;
end;

//*************************************************************//

destructor TIdSimpleWebSocketClient.Destroy;
begin
    lInternalLock.Free;
    if Self.AutoCreateHandler and assigned(Self.IOHandler) then
        Self.IOHandler.Free;
    inherited;
end;

//*************************************************************//

function TIdSimpleWebSocketClient.EncodeFrame(Msg: String; OpCode: TOpCode) : TIdBytes;
var
	FIN, MASK: Cardinal;
	MaskingKey: array [0 .. 3] of Cardinal;
	EXTENDED_PAYLOAD_LEN: array [0 .. 3] of Cardinal;
	Buffer: TIdBytes;
	I: Integer;
	Xor1, Xor2: char;
	ExtendedPayloadLength: Integer;
begin
    FIN := 0;
    FIN := Set_a_Bit(FIN, 7) or TOpCodeByte[OpCode];

    MASK := Set_a_Bit(0, 7);

    ExtendedPayloadLength := 0;
    if Msg.Length <= 125 then
        MASK := MASK + Msg.Length
    else if Msg.Length < IntPower(2, 16) then
        begin
        MASK := MASK + 126;
        ExtendedPayloadLength := 2;
        // https://stackoverflow.com/questions/13634240/delphi-xe3-integer-to-array-of-bytes
        // converts an integer to two bytes array
        EXTENDED_PAYLOAD_LEN[1] := Byte(Msg.Length);
        EXTENDED_PAYLOAD_LEN[0] := Byte(Msg.Length shr 8);
        end
    else
        begin
        MASK := MASK + 127;
        ExtendedPayloadLength := 4;
        EXTENDED_PAYLOAD_LEN[3] := Byte(Msg.Length);
        EXTENDED_PAYLOAD_LEN[2] := Byte(Msg.Length shr 8);
        EXTENDED_PAYLOAD_LEN[1] := Byte(Msg.Length shr 16);
        EXTENDED_PAYLOAD_LEN[0] := Byte(Msg.Length shr 32);
        end;
    MaskingKey[0] := random(255);
    MaskingKey[1] := random(255);
    MaskingKey[2] := random(255);
    MaskingKey[3] := random(255);

    SetLength(Buffer, 1 + 1 + ExtendedPayloadLength + 4 + Msg.Length);
    Buffer[0] := FIN;
    Buffer[1] := MASK;
    for I := 0 to ExtendedPayloadLength - 1 do
        Buffer[1 + 1 + I] := EXTENDED_PAYLOAD_LEN[I];
    // payload mask:
    for I := 0 to 3 do
        Buffer[1 + 1 + ExtendedPayloadLength + I] := MaskingKey[I];
    for I := 0 to Msg.Length - 1 do
        begin
    	{$IF DEFINED(iOS) or DEFINED(ANDROID)}
        Xor1 := Msg[I];
    	{$ELSE}
        Xor1 := Msg[I + 1];
    	{$ENDIF}
        Xor2 := Chr(MaskingKey[((I) mod 4)]);
        Xor2 := Chr(Ord(Xor1) xor Ord(Xor2));
        Buffer[1 + 1 + ExtendedPayloadLength + 4 + I] := Ord(Xor2);
        end;
    Result := Buffer;
end;

//*************************************************************//

function TIdSimpleWebSocketClient.Get_a_Bit(const aValue: Cardinal; const Bit: Byte): Boolean;
begin
	Result := (aValue and (1 shl Bit)) <> 0;
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.ReadFromWebSocket;
var
	lSpool: String;
	b: Byte;
	T: ITask;
	lPos: Integer;
	lSize: int64;
	lOpCode: Byte;
	linFrame: Boolean;
	lMasked: Boolean;
	lForceDisconnect: Boolean;
	lHeader: TStringlist;
	// lClosingRemoteHandshake:Boolean;
	// lPing:Boolean;
begin
    lSpool := '';
    lPos := 0;
    lSize := 0;
    lOpCode := 0;
    lMasked := false;
    FUpgraded := false;
    // lPing     := false;
    // pingByte  := Set_a_Bit(0,7); //1001001//PingByte
    // pingByte  := Set_a_Bit(pingByte,3);
    // pingByte  := Set_a_Bit(pingByte,0);
    // closeByte := Set_a_Bit(0,7);//1001000//CloseByte
    // closeByte := Set_a_Bit(closeByte,3);

    lHeader := TStringlist.Create;
    linFrame := false;

    try
        while Connected and not FUpgraded do
        // First, we guarantee that this is an valid Websocket
            begin
            b := Self.Socket.ReadByte;

            lSpool := lSpool + Chr(b);
            if (not FUpgraded and (b = Ord(#13))) then
                begin
                if lSpool = #10#13 then
                    begin

                    // verifies header
                    try
                        if not VerifyHeader(lHeader) then
                            begin
                            raise exception.Create
                              ('URL is not from an valid websocket server, not a valid response header found');
                            end;
                    finally
                        lHeader.Free;
                    end;

                    FUpgraded := true;
                    lSpool := '';
                    lPos := 0;
                    end
                else
                    begin
                    if assigned(OnConnectionDataEvent) then
                        OnConnectionDataEvent(Self, lSpool);

                    lHeader.Add(lSpool.Trim);
                    lSpool := '';
                    end;
                end;
            end;
    except
        on e: exception do
            begin
            lForceDisconnect := true;
            if assigned(Self.OnError) then
                Self.OnError(Self, e, e.Message, lForceDisconnect);
            if lForceDisconnect then
                Self.Close;
            exit;
            end;
    end;

    if Connected then
        if assigned(OnAfterConnectionDataEvent) then
            OnAfterConnectionDataEvent(Self, '');
        T := TTask.Run(
            procedure
            var
                extended_payload_length: Cardinal;
            begin
            extended_payload_length := 0;
            try
                while Connected do
                    begin

                    b := Self.Socket.ReadByte;

                    if FUpgraded and (lPos = 0) and Get_a_Bit(b, 7) then // FIN
                        begin
                        linFrame := true;
                        lOpCode := Clear_a_Bit(b, 7);

                        inc(lPos);

                        if lOpCode = TOpCodeByte[TOpCode.TOConnectionClose] then
                        end
                    else if FUpgraded and (lPos = 1) then
                        begin
                        lMasked := Get_a_Bit(b, 7);
                        lSize := b;
                        if lMasked then
                            lSize := b - Set_a_Bit(0, 7);
                        if lSize = 0 then
                            lPos := 0
                        else if lSize = 126 then // get size from 2 next bytes
                            begin
                            lSize := Self.Socket.ReadUInt16;
                            end
                        else if lSize = 127 then
                            begin
                            lSize := Self.Socket.ReadUInt64;
                            end;

                        inc(lPos);
                        end
                    else if linFrame then
                        begin
                        lSpool := lSpool + Chr(b);

                        if (FUpgraded and (Length(lSpool) = lSize)) then
                            begin
                            lPos := 0;
                            linFrame := false;

                            if lOpCode = TOpCodeByte[TOpCode.TOPing] then
                                begin
                                try
                                    lInternalLock.Enter;
                                    Self.Socket.Write(EncodeFrame(lSpool, TOpCode.TOPong));
                                finally
                                    lInternalLock.Leave;
                                end;

                                if assigned(OnPing) then
                                    OnPing(Self, lSpool);
                                end
                            else
                                begin
                                if FUpgraded and assigned(FOnDataEvent) and
                                  (not(lOpCode = TOpCodeByte
                                  [TOpCode.TOConnectionClose])) then
                                    onDataEvent(Self, lSpool);
                                if assigned(Self.lSyncFunctionTrigger) then
                                    begin
                                    if Self.lSyncFunctionTrigger(lSpool) then
                                        begin
                                        Self.lSyncFunctionEvent.SetEvent;
                                        end;
                                    end;
                                end;

                            lSpool := '';
                            if lOpCode = TOpCodeByte[TOpCode.TOConnectionClose] then
                                begin
                                if not Self.lClosingEventLocalHandshake then
                                    begin
                                    Self.Close;
                                    if assigned(Self.OnDisconnected) then
                                        Self.OnDisconnected(Self);
                                    end;
                                break
                                end;

                            end;
                        end;
                    end;
            except
                on e: exception do
                    begin
                    lForceDisconnect := true;
                    if assigned(Self.OnError) then
                        Self.OnError(Self, e, e.Message, lForceDisconnect);
                    if lForceDisconnect then
                        Self.Close;
                    end;
            end;
            end);

    if ((not Connected) or (not FUpgraded)) and
       (not((lOpCode = TOpCodeByte[TOpCode.TOConnectionClose]) or
        lClosingEventLocalHandshake)) then
        begin

        raise exception.Create('Websocket not connected or timeout' +
        	QuotedStr(lSpool));
        end
    else if assigned(Self.OnUpgrade) then
        Self.OnUpgrade(Self);

end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.StartHeartBeat;
var
	TimeUltimaNotif: TDateTime;
	lForceDisconnect: Boolean;
begin
    TThread.CreateAnonymousThread(
        procedure
        begin
        TimeUltimaNotif := Now;
        try
            while (Self.Connected) and (Self.HeartBeatInterval > 0) do
                begin
                // HeartBeat:
                if (MilliSecondsBetween(TimeUltimaNotif, Now) >= Floor(Self.HeartBeatInterval)) then
                    begin
                    if assigned(Self.OnHeartBeatTimer) then
                        Self.OnHeartBeatTimer(Self);
                    TimeUltimaNotif := Now;
                    end;
                TThread.Sleep(500);
                end;
        except
            on e: exception do
                begin
                lForceDisconnect := true;
                if assigned(Self.OnError) then
                    Self.OnError(Self, e, e.Message, lForceDisconnect);
                if lForceDisconnect then
                    Self.Close;
                end;
        end;

        end).Start;
end;

//*************************************************************//

function TIdSimpleWebSocketClient.VerifyHeader(Header: TStrings): Boolean;
begin
    Header.NameValueSeparator := ':';
    Result := false;
    if (pos('HTTP/1.1 101', Header[0]) = 0) and (pos('HTTP/1.1', Header[0]) > 0)
    then
        raise exception.Create(Header[0].SubString(9));

    if (Header.Values['Connection'].Trim.ToLower = 'upgrade') and
      (Header.Values['Upgrade'].Trim.ToLower = 'websocket') then
        begin
        if Header.Values['Sec-WebSocket-Accept'].Trim = Self.SecWebSocketAcceptExpectedResponse
        then
            Result := true
        else if Header.Values['Sec-WebSocket-Accept'].Trim.IsEmpty then
            Result := true
        else
            raise exception.Create
              ('Unexpected return key on Sec-WebSocket-Accept in handshake');

        end;
end;

//*************************************************************//

function TIdSimpleWebSocketClient.Set_a_Bit(const aValue: Cardinal; const Bit: Byte): Cardinal;
begin
	Result := aValue or (1 shl Bit);
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.WriteText(Msg: String);
begin
    try
        lInternalLock.Enter;
        Self.Socket.Write(EncodeFrame(Msg));
    finally
        lInternalLock.Leave;
    end;
end;

//*************************************************************//

procedure TIdSimpleWebSocketClient.WriteTextSync(Msg: String; pTriggerFunction: TFunc<String, Boolean>);
begin
    Self.lSyncFunctionTrigger := pTriggerFunction;
    try
        Self.lSyncFunctionEvent := TSimpleEvent.Create();
        Self.lSyncFunctionEvent.ResetEvent;
        Self.WriteText(Msg);
        Self.lSyncFunctionEvent.WaitFor(Self.ReadTimeout);

    finally
        Self.lSyncFunctionTrigger := nil;
        Self.lSyncFunctionEvent.Free;
    end;
end;

//*************************************************************//

end.
