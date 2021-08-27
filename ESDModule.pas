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
    FreeAndNil(FActionToContext);
    FreeAndNil(FContextToAction);
end;

//*************************************************************//
// https://developer.elgato.com/documentation/stream-deck/sdk/events-received/#didreceivesettings

procedure	TESDPlugin.DidReceiveSettings(const Action, Context: String; const JSONPayload: TJSONObject; const DeviceID: String);
var
    JSONPair:		TJSONPair;
    JSONSettings:	TJSONObject;
    Command, Value: String;
begin
    if JSONPayload.FindValue('settings') <> nil then
        begin
        JSONPair := JSONPayload.Get('settings');
        JSONSettings := JSONPair.JsonValue as TJSONObject;
        Command := GetJSONStr(JSONSettings, 'command');
        Value := GetJSONStr(JSONSettings, 'value');
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
    FActionToContext.Add(Action, Context);
    FContextToAction.Add(Context, Action);

    GConnectionManager.RequestSettings(Context);
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
    JSONObject := nil;
    JSONObject := TJSONObject.Create;
    try

    // Based on Generic PI, or Button Specific PI on Action and/or Context -
    // Build up your JSON to send to Property Inspector to handle in its OnMessage callback (see javascript in HTML)
    // HTML file is identified in manifest.json
    //
    // JSON Owned property used b/c JSON objects created in the connection manager can take passed in JSON objects as
    // payloads.  When those objects are free'd, we don't want to free our object there.  We free it here.

    JSONObject.Owned := False;
    if JSONObject.Count > 0 then
        GConnectionManager.SendToPropertyInspector(Action, Context, JSONObject);
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
    if JSONPayload.FindValue('...') <> nil then
	    begin
            // Command is our key
            Command := 'some command';
            Value := GetJSONStr(JSONPayload, '...');

            // Command / Value key pair needs to be saved so it can be restored on next run when we get our settings
            JSONSettings := nil;
            JSONSettings := TJSONObject.Create;
            try
                JSONSettings.AddPair('command', Command);
                JSONSettings.AddPair('value', Value);
                JSONSettings.AddPair('context', Context);
                JSONSettings.Owned := False;
                GConnectionManager.SetSettings(JSONSettings, Context);
            finally
                JSONSettings.Owned := True;
                FreeAndNil(JSONSettings);
            end;
        end;
end;

//*************************************************************//

end.
