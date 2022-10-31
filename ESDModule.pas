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
unit ESDModule;

interface

uses
  WinApi.Windows,
  System.SysUtils, System.Classes, System.Generics.Collections,
  System.JSON, System.SyncObjs, System.StrUtils,
  ESDSDKDefines;

type
  TESDPlugin = class
  private
    FContextToAction: TDictionary<String, String>;
    FContextToValue:  TDictionary<String, String>;

    FLangList: array[1..11] of String; // Will hold the list of languages in the HTML (could be done better, this just an example)

  public
    constructor	Create;
		destructor	Destroy; override;
    procedure	DidReceiveSettings(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	DidReceiveGlobalSettings(const JSONPayload: TJSONObject);
    procedure	KeyDownForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	KeyUpForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	WillAppearForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	WillDisappearForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	TitleParametersDidChange(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	DeviceDidConnect(const DeviceID: String; const JSONDevice: TJSONObject);
    procedure	DeviceDidDisconnect(const DeviceID: String);
    procedure	ApplicationDidLaunch(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	ApplicationDidTerminate(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	SystemDidWakeUp;
    procedure	PropertyInspectorDidAppear(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
    procedure	PropertyInspectorDidDisappear(const Action, Context, DeviceID: String);
    procedure	SendToPlugin(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
  end;

//*************************************************************//

implementation

uses
	ESDConnectionManager;

//*************************************************************//

constructor	TESDPlugin.Create;
begin
  FContextToAction := TDictionary<String, String>.Create;
  FContextToValue  := TDictionary<String, String>.Create;

  // This list will be reconstructed via HTML with the proper option selected (either initial or after first selection)
  FLangList[1] := 'Pascal';
  FLangList[2] := 'C';
  FLangList[3] := 'C++';
  FLangList[4] := 'C#';
  FLangList[5] := 'JavaScript';
  FLangList[6] := 'COBOL';
  FLangList[7] := 'BASIC';
  FLangList[8] := 'Rust';
  FLangList[9] := 'PHP';
  FLangList[10] := 'Perl';
  FLangList[11] := 'Ruby';
end;

//*************************************************************//

destructor	TESDPlugin.Destroy;
begin
  FreeAndNil(FContextToAction);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#didreceivesettings

procedure	TESDPlugin.DidReceiveSettings(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
  JSONPair:		    TJSONPair;
  JSONSettings:	  TJSONObject;
  Command, Value: String;
begin
  if JSONPayload.FindValue('settings') <> nil then
    begin
      JSONPair := JSONPayload.Get('settings');
      JSONSettings := JSONPair.JsonValue as TJSONObject;
      Command := GetJSONStr(JSONSettings, 'command');
      Value := GetJSONStr(JSONSettings, 'value');
      FContextToValue.AddOrSetValue(Context, Value);
    end;
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#didreceiveglobalsettings

procedure	TESDPlugin.DidReceiveGlobalSettings(const JSONPayload: TJSONObject);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#keydown

procedure	TESDPlugin.KeyDownForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  //GConnectionManager.SetImage(GetBase64Image('C:\Users\andyb\AppData\Roaming\Elgato\StreamDeck\IconPacks\de.streamdeck-fx.sdfxmatrix.sdIconPack\icons\elgato_fx_matrix_025_30C900.png'), Context, kESDSDKTarget_HardwareAndSoftware);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#keyup

procedure	TESDPlugin.KeyUpForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#willappear

procedure	TESDPlugin.WillAppearForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  FContextToAction.Add(Context, Action);
  GConnectionManager.RequestSettings(Context);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#willdisappear

procedure	TESDPlugin.WillDisappearForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  FContextToAction.Remove(Context);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#titleparametersdidchange

procedure	TESDPlugin.TitleParametersDidChange(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#devicediddisconnect

procedure	TESDPlugin.DeviceDidConnect(const DeviceID: String; const JSONDevice: TJSONObject);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#devicediddisconnect

procedure	TESDPlugin.DeviceDidDisconnect(const DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#applicationdidlaunch

procedure	TESDPlugin.ApplicationDidLaunch(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#applicationdidterminate

procedure	TESDPlugin.ApplicationDidTerminate(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#systemDidWakeUp

procedure	TESDPlugin.SystemDidWakeUp;
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#propertyinspectordidappear

// Based on Generic Property Inspector (The generic HTML for all buttons),
// or the button specific Property Inspector on Context and/or Action - Context is unique, Action may not be
// Build up your JSON to send to Property Inspector to handle in its OnMessage callback (see javascript in HTML)
// HTML file is identified in manifest.json
procedure	TESDPlugin.PropertyInspectorDidAppear(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
  JSONObject: TJSONObject;
  idx:        Integer;
  HTML, Lang: String;
begin
  JSONObject := nil;
  try
    // See if the Context contains the action.
    // The context is used because a button could be dropped multiple times on the stream deck
    // Which causes it to have the same Action which can't be used to uniquely identify multiple versions of this button
    // This is not typical but it is possible and why Context should be used to store state
    if (FContextToValue.ContainsKey(Context) = True) then
      begin
        JSONObject := TJSONObject.Create;
        JSONObject.Owned := False;

        if (Action = 'com.org.software.mybutton') then // The control representing the selection and its options
          begin
            Lang := FContextToValue[Context];
            HTML := '<optgroup label="Languages">';
            for idx := 1 to Length(FLangList) do
              begin
                HTML := HTML + '<option value="' + FLangList[idx] + '"';
                if (FLangList[idx] = Lang) then
                  HTML := HTML + ' selected';
                HTML := HTML + '>' + FLangList[idx] + '</option>';
              end;
            HTML := HTML + '</optgroup>';

            // Add the languages as children data to the object passed to the property inspector
            // The javascript will parse it out and build the html
            JSONObject.AddPair(Context, HTML);

            {$IFDEF DEBUG}
            OutputDebugString(PWideChar(format('%s', [JSONObject.Format(4)])));
            {$ENDIF}

            // Update HTML to process JSON and act on it. -> In our case it will select the previously selected list item
            GConnectionManager.SendToPropertyInspector(Action, Context, JSONObject);
          end;
      end;
  finally
      JSONObject.Owned := True;
      FreeAndNil(JSONObject);
  end;
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#propertyinspectordiddisappear

procedure	TESDPlugin.PropertyInspectorDidDisappear(const Action, Context, DeviceID: String);
begin
  // Nothing to do yet
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#sendtoplugin

procedure	TESDPlugin.SendToPlugin(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
  JSONSettings:	TJSONObject;
  Command, Value:	String;
begin
  // Property Inspector sent us something based on one of our HTML custom events (see HTML)
  {$IFDEF DEBUG}
  OutputDebugString(PWideChar(format('%s', [JSONPayload.Format(4)])));
  {$ENDIF}

  Command := 'MySelect';
  if JSONPayload.FindValue(Command) <> nil then
    begin
      // Command is our key
      Value := GetJSONStr(JSONPayload, Command);

      // Command / Value key pair needs to be saved so it can be restored on next run when we get our settings
      JSONSettings := nil;
      JSONSettings := TJSONObject.Create;
      try
          JSONSettings.AddPair('command', Command);
          JSONSettings.AddPair('value', Value);
          JSONSettings.AddPair('context', Context);
          JSONSettings.Owned := False;
          GConnectionManager.SetSettings(JSONSettings, Context);
          GConnectionManager.RequestSettings(Context);
      finally
          JSONSettings.Owned := True;
          FreeAndNil(JSONSettings);
      end;
    end;
end;

//*************************************************************//

end.
