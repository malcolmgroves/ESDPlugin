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
        FActionToContext: TDictionary<String, String>;
        FContextToAction: TDictionary<String, String>;

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
    FActionToContext := TDictionary<String, String>.Create;
    FContextToAction := TDictionary<String, String>.Create;
end;

//*************************************************************//

destructor	TESDPlugin.Destroy;
begin
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#didreceivesettings

procedure	TESDPlugin.DidReceiveSettings(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
    JSONPair : TJSONPair;
    JSONSettings: TJSONObject;
begin
    if JSONPayload.FindValue('settings') <> nil then
        begin
        JSONPair := JSONPayload.Get('settings');
        JSONSettings := JSONPair.JsonValue as TJSONObject;

        // Pull out your payload data with GetJSONStr
        // ex: Value := GetJSONStr(JSONSettings, 'Key');  for something like {"Key":"Value"}
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
    // Nothing to do yet
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
    FActionToContext.Add(Action, Context);
    FContextToAction.Add(Context, Action);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#willdisappear

procedure	TESDPlugin.WillDisappearForAction(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
begin
    FActionToContext.Remove(Action);
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

procedure	TESDPlugin.PropertyInspectorDidAppear(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
    JSONObject: TJSONObject;
begin
    JSONObject := TJSONObject.Create;

    // Based on Generic PI, or Button Specific PI on Action and/or Context -
    // Build up your JSON to send to Property Inspector to handle in its OnMessage callback (see javascript in HTML)
    // HTML file is identified in manifest.json

    if JSONObject.Count > 0 then
        GConnectionManager.SendToPropertyInspector(Action, Context, JSONObject);
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
    Value: String;
begin
    // Property Inspector sent us something based on one of our HTML custom events (see HTML)
    if JSONPayload.FindValue('MyInput') <> nil then
	    begin
            Value := GetJSONStr(JSONPayload, 'MyInput');
            GConnectionManager.SetTitle(Value, Context, kESDSDKTarget_HardwareAndSoftware);
        end;

    if JSONPayload.FindValue('MySelect') <> nil then
	    begin
            Value := GetJSONStr(JSONPayload, 'MySelect');
            GConnectionManager.SetTitle(Value, Context, kESDSDKTarget_HardwareAndSoftware);
        end;
end;

//*************************************************************//

end.
