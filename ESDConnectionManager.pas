{
    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
}
unit ESDConnectionManager;

interface

uses
  WinApi.Windows,
  System.SysUtils, System.Classes, System.StrUtils, System.JSON,
  IdSSLOpenSSL, IdWebSocketSimpleClient,
  ESDModule, ESDSDKDefines;

type
  TESDConnectionManager = class(TComponent)

  private
    FPort: Integer;
    FPluginUUID: String;
    FRegisterEvent: String;
    FInfo: String;
    FWebSocket: TIdSimpleWebSocketClient;
    FESDPlugin: TESDPlugin;

    // WebSocket callbacks
    procedure	OnConnectionEvent(Sender: TObject; const Text: String);
    procedure   OnAfterConnectionEvent(Sender: TObject; const Text: String);
    procedure	OnDataEvent(Sender: TObject; const Text: String);
    procedure	OnPingEvent(Sender: TObject; const Text: String);
    procedure   OnErrorEvent(Sender: TObject; Exception: Exception; const Text: String; var ForceDisconnect);
    procedure   OnUpgradeEvent(Sender: TObject);
    procedure   OnDisconnectedEvent(Sender: TObject);

  public
    constructor	Create(Port: Integer; PluginUUID, RegisterEvent, Info: String; ESDPlugin: TESDPlugin); reintroduce;
    procedure   AfterConstruction; override;
    destructor	Destroy; override;
    procedure	Run;

    // API to communicate with the Stream Deck Application
    procedure	SetTitle(const Title, Context: String; Target: ESDSDKTarget);
    procedure	SetImage(const Image64, Context: String; Target: ESDSDKTarget; const MimeType: ESDSDKMimeTypes = kESDSDKMimeType_png);
    procedure	ShowAlertForContext(const Context: String);
    procedure	ShowOKForContext(const Context: String);
    procedure	SetSettings(const JSONSettings: TJSONObject; const Context: String);
    procedure	SetState(State: Integer; const Context: String);
    procedure	SendToPropertyInspector(const Action, Context: String; const Payload: TJSONObject);
    procedure	SwitchToProfile(const DeviceID, ProfileName: String);
    procedure	LogMessage(const Message: String);
    procedure	SetGlobalSettings(const Settings: TJSONObject);
    procedure	RequestSettings(const Context: String);
    procedure	RequestGlobalSettings();
  end;

//*************************************************************//

function GetJSONStr(const JSONObj: TJSONObject; const JSONFieldName: String): Variant;

//*************************************************************//

var
  GConnectionManager: TESDConnectionManager;

implementation

//*************************************************************//

function GetJSONStr(const JSONObj: TJSONObject; const JSONFieldName: String): Variant;
begin
  if (JSONObj.Get(JSONFieldName) <> Nil) and (JSONObj.Get(JSONFieldName).JsonValue is TJSONString) then
    Result := TJSONString(JSONObj.Get(JSONFieldName).JsonValue).Value
  else
    Result := '';
end;

//*************************************************************//

constructor TESDConnectionManager.Create(Port: Integer; PluginUUID, RegisterEvent, Info: String; ESDPlugin: TESDPlugin);
begin
  inherited Create(nil);

    FPort := Port;
    FPluginUUID := PluginUUID;
    FRegisterEvent := RegisterEvent;
    FInfo := Info;
    FESDPlugin := ESDPlugin;
end;

//*************************************************************//

procedure TESDConnectionManager.AfterConstruction;
begin
  inherited;
  GConnectionManager := Self;
end;

//*************************************************************//

destructor TESDConnectionManager.Destroy;
begin
	inherited;
end;

//*************************************************************//

procedure TESDConnectionManager.Run;
begin
  try
    FWebSocket := TIdSimpleWebSocketClient.Create(Self);
    FWebSocket.OnConnectionDataEvent := OnConnectionEvent;
    FWebSocket.OnAfterConnectionDataEvent := OnAfterConnectionEvent;
    FWebSocket.OnUpgrade := OnUpgradeEvent;
    FWebSocket.OnDataEvent := OnDataEvent;
    FWebSocket.OnPing := OnPingEvent;
    FWebSocket.OnError := OnErrorEvent;
    FWebSocket.OnDisconnected := OnDisconnectedEvent;
    FWebSocket.AutoCreateHandler := False; // This can be set as True in the majority of Websockets with ssl

    if not FWebSocket.AutoCreateHandler then
    begin
      if FWebSocket.IOHandler = nil then
      FWebSocket.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(FWebSocket);
      (FWebSocket.IOHandler as TIdSSLIOHandlerSocketOpenSSL).SSLOptions.Mode := TIdSSLMode.sslmClient;
      (FWebSocket.IOHandler as TIdSSLIOHandlerSocketOpenSSL).SSLOptions.SSLVersions := [TIdSSLVersion.sslvTLSv1, TIdSSLVersion.sslvTLSv1_1, TIdSSLVersion.sslvTLSv1_2];
    end;

    FWebSocket.Connect('ws://127.0.0.1:' + IntToStr(FPort));

    except
      on E: Exception do
        OutputDebugString(PWideChar(format('%s : %s', [E.ClassName, E.Message])));
    end;
end;

//*************************************************************//

// WebSocket Callbacks

//*************************************************************//

procedure TESDConnectionManager.OnConnectionEvent(Sender: TObject; const Text: String);
begin
  OutputDebugString(PWideChar(format('%s', [Text])));
end;

//*************************************************************//

procedure TESDConnectionManager.OnAfterConnectionEvent(Sender: TObject; const Text: String);
var
  JSONRegister: TJSONObject;
  JSON: String;
begin
  // The connection was established, register the plugin
  JSONRegister := nil;
  JSONRegister := TJSONObject.Create;
  try
    JSONRegister.AddPair('event', kESDSDKRegisterPlugin);
    JSONRegister.AddPair('uuid', FPluginUUID);
    JSON := JSONRegister.ToString;
    FWebSocket.WriteText(JSONRegister.ToString);
    OutputDebugString(PWideChar(format('%s', [JSONRegister.ToString])));
  finally
    FreeAndNil(JSONRegister);
  end;
end;

//*************************************************************//

procedure TESDConnectionManager.OnDataEvent(Sender: TObject; const Text: String);
var
  JSONData, JSONPayload, JSONDevice: TJSONObject;
  JSONPayloadPair, JSONDevicePair: TJSONPair;
  Event, Context, Action, DeviceID : String;
begin
  // Block once here for in code visual updates to the buttons
  TMonitor.Enter(Self);

  // https://developer.elgato.com/documentation/stream-deck/sdk/events-received/
	try
    JSONData := TJSONObject.ParseJSONValue(Text) as TJSONObject;

    Event := GetJSONStr(JSONData, kESDSDKCommonEvent);
    Context := GetJSONStr(JSONData, kESDSDKCommonContext);
    Action := GetJSONStr(JSONData, kESDSDKCommonAction);
    DeviceID := GetJSONStr(JSONData, kESDSDKCommonDevice);

    JSONPayloadPair := JSONData.Get(kESDSDKCommonPayload);
    JSONPayload := nil;
    if Assigned(JSONPayloadPair) then
      JSONPayload := JSONPayloadPair.JsonValue as TJSONObject;

    if Event = kESDSDKEventDidReceiveSettings then
      begin
        if Assigned(JSONPayload) then
          begin
            FESDPlugin.DidReceiveSettings(Action, Context, JSONPayload, DeviceID);
            OutputDebugString(PWideChar(format('Event %s', [Event])));
          end;
      end
    else if Event = kESDSDKEventDidReceiveGlobalSettings then
      begin
        FESDPlugin.DidReceiveGlobalSettings(JSONPayload);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventKeyDown then
      begin
        FESDPlugin.KeyDownForAction(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventKeyUp then
      begin
        FESDPlugin.KeyUpForAction(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventWillAppear then
      begin
        FESDPlugin.WillAppearForAction(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventWillDisappear then
      begin
        FESDPlugin.WillDisappearForAction(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventTitleParametersDidChange then
      begin
        FESDPlugin.TitleParametersDidChange(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventDeviceDidConnect then
      begin
        JSONDevicePair := JSONData.Get(kESDSDKCommonDeviceInfo);
        if Assigned(JSONDevicePair) then
          begin
            JSONDevice := JSONDevicePair.JsonValue as TJSONObject;
            FESDPlugin.DeviceDidConnect(DeviceID, JSONDevice);
            OutputDebugString(PWideChar(format('Event %s', [Event])));
          end;
      end
    else if Event = kESDSDKEventDeviceDidDisconnect then
      begin
        FESDPlugin.DeviceDidDisconnect(DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventApplicationDidLaunch then
      begin
        FESDPlugin.ApplicationDidLaunch(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventApplicationDidTerminate then
      begin
        FESDPlugin.ApplicationDidTerminate(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventSystemDidWakeUp then
      begin
        FESDPlugin.SystemDidWakeUp;
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventPropertyInspectorDidAppear then
      begin
        FESDPlugin.PropertyInspectorDidAppear(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventPropertyInspectorDidDisappear then
      begin
        FESDPlugin.PropertyInspectorDidDisappear(Action, Context, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end
    else if Event = kESDSDKEventSendToPlugin then
      begin
        FESDPlugin.SendToPlugin(Action, Context, JSONPayload, DeviceID);
        OutputDebugString(PWideChar(format('Event %s', [Event])));
      end;
    finally
    	TMonitor.Exit(Self);
	end;
    OutputDebugString(PWideChar(format('%s', [Text])));
end;

//*************************************************************//

procedure TESDConnectionManager.OnPingEvent(Sender: TObject; const Text: String);
begin
    OutputDebugString(PWideChar(format('%s', [Text])));
end;

//*************************************************************//

procedure TESDConnectionManager.OnErrorEvent(Sender: TObject; Exception: Exception; const Text: String; var ForceDisconnect);
begin
    OutputDebugString(PWideChar(format('%s : %s - %s', [Exception.ClassName, Exception.Message, Text])));
end;

//*************************************************************//

procedure TESDConnectionManager.OnUpgradeEvent(Sender: TObject);
begin
    OutputDebugString(PWideChar(format('%s', ['Upgrade'])));
end;

//*************************************************************//

procedure TESDConnectionManager.OnDisconnectedEvent(Sender: TObject);
begin
    OutputDebugString(PWideChar(format('%s', ['Disconnected'])));
end;

//*************************************************************//

// API to communicate with the Stream Deck Application

//*************************************************************//

procedure TESDConnectionManager.SetTitle(const Title, Context: String; Target: ESDSDKTarget);
var
    JSONObject, JSONPayload: TJSONObject;
begin
    JSONObject := nil;
    JSONPayload := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSetTitle);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        JSONPayload := TJSONObject.Create;
        JSONPayload.AddPair(kESDSDKPayloadTarget, TJSONNumber.Create(Ord(Target)));
        JSONPayload.AddPair(kESDSDKPayloadTitle, Title);

        JSONObject.AddPair(kESDSDKCommonPayload, JSONPayload);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.SetImage(const Image64, Context: String; Target: ESDSDKTarget; const MimeType: ESDSDKMimeTypes);
var
    JSONObject, JSONPayload: TJSONObject;
    Prefix: String;
begin
    case MimeType of
        kESDSDKMimeType_jpg: Prefix := 'data:image/jpg;base64,';
        kESDSDKMimeType_bmp: Prefix := 'data:image/bmp;base64,';
        kESDSDKMimeType_svg: Prefix := 'data:image/svg+xml;charset=utf8,';
    else
        Prefix := 'data:image/png;base64,';
    end;

    JSONObject := nil;
    JSONPayload := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSetImage);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        JSONPayload := TJSONObject.Create;
        JSONPayload.AddPair(kESDSDKPayloadTarget, TJSONNumber.Create(Ord(Target)));
        if (Length(Image64) = 0) or (Pos(Prefix, Image64) = 1) then
            JSONPayload.AddPair(kESDSDKPayloadImage, Image64)
        else
            JSONPayload.AddPair(kESDSDKPayloadImage, Prefix + Image64);
        JSONObject.AddPair(kESDSDKCommonPayload, JSONPayload);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.ShowAlertForContext(const Context: String);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventShowAlert);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.ShowOKForContext(const Context: String);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventShowOK);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.SetSettings(const JSONSettings: TJSONObject; const Context: String);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSetSettings);
        JSONObject.AddPair(kESDSDKCommonContext, Context);
        JSONObject.AddPair(kESDSDKCommonPayload, JSONSettings);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.SetState(State: Integer; const Context: String);
var
    JSONObject, JSONPayload: TJSONObject;
begin
    JSONObject := nil;
    JSONPayload := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSetState);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        JSONPayload := TJSONObject.Create;
        JSONPayload.AddPair(kESDSDKPayloadState, TJSONNumber.Create(State));
        JSONObject.AddPair(kESDSDKCommonPayload, JSONPayload);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.SendToPropertyInspector(const Action, Context: String; const Payload: TJSONObject);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSendToPropertyInspector);
        JSONObject.AddPair(kESDSDKCommonContext, Context);
        JSONObject.AddPair(kESDSDKCommonAction, Action);
        JSONObject.AddPair(kESDSDKCommonPayload, Payload);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.SwitchToProfile(const DeviceID, ProfileName: String);
var
    JSONObject, JSONPayload: TJSONObject;
begin
    if Length(DeviceID) > 0 then
    	begin
        JSONObject := nil;
        JSONPayload := nil;
        JSONObject := TJSONObject.Create;
            try
            JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSwitchToProfile);
            JSONObject.AddPair(kESDSDKCommonContext, FPluginUUID);
            JSONObject.AddPair(kESDSDKCommonDevice, DeviceID);

            if Length(ProfileName) > 0 then
                begin
                JSONPayload := TJSONObject.Create;
                JSONPayload.AddPair(kESDSDKPayloadProfile, ProfileName);
                JSONObject.AddPair(kESDSDKCommonPayload, JSONPayload);
                end;

            FWebSocket.WriteText(JSONObject.ToString);
            finally
                FreeAndNil(JSONObject);
            end;
        end;
end;

//*************************************************************//

procedure TESDConnectionManager.LogMessage(const Message: String);
var
    JSONObject, JSONPayload: TJSONObject;
begin
    if Length(Message) > 0 then
        begin
        JSONObject := nil;
        JSONPayload := nil;
        JSONObject := TJSONObject.Create;
        try
            JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventLogMessage);

            JSONPayload := TJSONObject.Create;
            JSONPayload.AddPair(kESDSDKPayloadMessage, Message);
            JSONObject.AddPair(kESDSDKCommonPayload, JSONPayload);

            FWebSocket.WriteText(JSONObject.ToString);
        finally
            FreeAndNil(JSONObject);
        end;
        end;
end;

//*************************************************************//

procedure TESDConnectionManager.SetGlobalSettings(const Settings: TJSONObject);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventSetGlobalSettings);
        JSONObject.AddPair(kESDSDKCommonContext, FPluginUUID);
        JSONObject.AddPair(kESDSDKCommonPayload, Settings);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.RequestSettings(const Context: String);
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventGetSettings);
        JSONObject.AddPair(kESDSDKCommonContext, Context);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

procedure TESDConnectionManager.RequestGlobalSettings();
var
    JSONObject: TJSONObject;
begin
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try
        JSONObject.AddPair(kESDSDKCommonEvent, kESDSDKEventGetGlobalSettings);
        JSONObject.AddPair(kESDSDKCommonContext, FPluginUUID);

        FWebSocket.WriteText(JSONObject.ToString);
    finally
        FreeAndNil(JSONObject);
    end;
end;

//*************************************************************//

end.
