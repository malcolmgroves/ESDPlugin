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
program ESDPlugin;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  WinApi.Windows,
  WinApi.ShellAPI,
  System.SysUtils,
  System.JSON,
  IdContext,
  IdWebSocketSimpleClient,
  ESDSDKDefines,
  ESDConnectionManager,
  {$IFDEF DEBUG}
  VCL.Dialogs,
  {$ENDIF}
  ESDModule in 'ESDModule.pas';

//*************************************************************//

type
  TPWideCharArray = array[0..0] of PWideChar;

var
    Count, ArgCount:	Integer;
    Argv:				PPWideChar;
    CommandLine:		String;
    Parm, Value:		String;
    Port:				Integer;
    PluginUUID:			String;
    RegisterEvent:		String;
    Info:				String;
    Plugin:				TESDPlugin;
    ConnectionManager:	TESDConnectionManager;

    //*************************************************************//

begin
	try
        {$IFDEF DEBUG}
        ShowMessage('Attach to debugger to debug ESDPlugin');
        {$ENDIF}
        CommandLine := GetCommandLine;
        Argv := CommandLineToArgvW(PChar(CommandLine), ArgCount);
        if Not Assigned(Argv) or (ArgCount <> 9) then
            begin
            OutputDebugString(PWideChar(format('Invalid number of parameters %d instead of 9', [ArgCount])));
            exit;
            end;

        Port := 0;
        for Count := 0 to 3 do
            begin
            Parm := TPWideCharArray(Argv^)[1 + 2 * Count];
            Value := TPWideCharArray(Argv^)[1 + 2 * Count + 1];
            if Parm = kESDSDKPortParameter then
                Port := StrToInt(Value)
            else if Parm = kESDSDKPluginUUIDParameter then
                PluginUUID := Value
            else if Parm = kESDSDKRegisterEventParameter then
                RegisterEvent := Value
            else if Parm = kESDSDKInfoParameter then
                Info := Value;
            end;

        if Port = 0 then
            begin
            OutputDebugString(PWideChar('Missing port number'));
            exit;
            end;

        if Length(PluginUUID) = 0 then
            begin
            OutputDebugString(PWideChar('Missing plugin UUID'));
            exit;
            end;

        if Length(RegisterEvent) = 0 then
            begin
            OutputDebugString(PWideChar('Missing registerEvent'));
            exit;
            end;

        if Length(Info) = 0 then
            begin
            OutputDebugString(PWideChar('Missing info'));
            exit;
            end;

        Plugin := TESDPlugin.Create;
        ConnectionManager := TESDConnectionManager.Create(Port, PluginUUID, RegisterEvent, Info, Plugin);
        ConnectionManager.Run;
	except
		on E: Exception do
			OutputDebugString(PWideChar(format('%s : %s', [E.ClassName, E.Message])));
  end;
end.
