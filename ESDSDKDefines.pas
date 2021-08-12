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
unit ESDSDKDefines;

interface

uses
	System.SysUtils;

const

	//
	// Current version of the SDK
	//

	kESDSDKVersion								= 2;


	//
	// Common base-interface
	//

	kESDSDKCommonAction							= 'action';
	kESDSDKCommonEvent							= 'event';
	kESDSDKCommonContext						= 'context';
	kESDSDKCommonPayload						= 'payload';
	kESDSDKCommonDevice							= 'device';
	kESDSDKCommonDeviceInfo						= 'deviceInfo';


	//
	// Events
	//

	kESDSDKEventKeyDown							= 'keyDown';
	kESDSDKEventKeyUp							= 'keyUp';
	kESDSDKEventWillAppear						= 'willAppear';
	kESDSDKEventWillDisappear					= 'willDisappear';
	kESDSDKEventDeviceDidConnect				= 'deviceDidConnect';
	kESDSDKEventDeviceDidDisconnect				= 'deviceDidDisconnect';
	kESDSDKEventApplicationDidLaunch			= 'applicationDidLaunch';
	kESDSDKEventApplicationDidTerminate			= 'applicationDidTerminate';
	kESDSDKEventSystemDidWakeUp					= 'systemDidWakeUp';
	kESDSDKEventTitleParametersDidChange		= 'titleParametersDidChange';
	kESDSDKEventDidReceiveSettings				= 'didReceiveSettings';
	kESDSDKEventDidReceiveGlobalSettings		= 'didReceiveGlobalSettings';
	kESDSDKEventPropertyInspectorDidAppear		= 'propertyInspectorDidAppear';
	kESDSDKEventPropertyInspectorDidDisappear	= 'propertyInspectorDidDisappear';


	//
	// Functions
	//

	kESDSDKEventSetTitle						= 'setTitle';
	kESDSDKEventSetImage						= 'setImage';
	kESDSDKEventShowAlert						= 'showAlert';
	kESDSDKEventShowOK							= 'showOk';
	kESDSDKEventGetSettings						= 'getSettings';
	kESDSDKEventSetSettings						= 'setSettings';
	kESDSDKEventGetGlobalSettings				= 'getGlobalSettings';
	kESDSDKEventSetGlobalSettings				= 'setGlobalSettings';
	kESDSDKEventSetState						= 'setState';
	kESDSDKEventSwitchToProfile					= 'switchToProfile';
	kESDSDKEventSendToPropertyInspector			= 'sendToPropertyInspector';
	kESDSDKEventSendToPlugin					= 'sendToPlugin';
	kESDSDKEventOpenURL							= 'openUrl';
	kESDSDKEventLogMessage						= 'logMessage';


	//
	// Payloads
	//

	kESDSDKPayloadSettings						= 'settings';
	kESDSDKPayloadCoordinates					= 'coordinates';
	kESDSDKPayloadState							= 'state';
	kESDSDKPayloadUserDesiredState				= 'userDesiredState';
	kESDSDKPayloadTitle							= 'title';
	kESDSDKPayloadTitleParameters				= 'titleParameters';
	kESDSDKPayloadImage							= 'image';
	kESDSDKPayloadURL							= 'url';
	kESDSDKPayloadTarget						= 'target';
	kESDSDKPayloadProfile						= 'profile';
	kESDSDKPayloadApplication					= 'application';
	kESDSDKPayloadIsInMultiAction				= 'isInMultiAction';
	kESDSDKPayloadMessage						= 'message';

	kESDSDKPayloadCoordinatesColumn				= 'column';
	kESDSDKPayloadCoordinatesRow				= 'row';

	//
	// Device Info
	//

	kESDSDKDeviceInfoID							= 'id';
	kESDSDKDeviceInfoType						= 'type';
	kESDSDKDeviceInfoSize						= 'size';
	kESDSDKDeviceInfoName						= 'name';

	kESDSDKDeviceInfoSizeColumns				= 'columns';
	kESDSDKDeviceInfoSizeRows					= 'rows';


	//
	// Title Parameters
	//

	kESDSDKTitleParametersShowTitle				= 'showTitle';
	kESDSDKTitleParametersTitleColor			= 'titleColor';
	kESDSDKTitleParametersTitleAlignment		= 'titleAlignment';
	kESDSDKTitleParametersFontFamily			= 'fontFamily';
	kESDSDKTitleParametersFontSize				= 'fontSize';
	kESDSDKTitleParametersCustomFontSize		= 'customFontSize';
	kESDSDKTitleParametersFontStyle				= 'fontStyle';
	kESDSDKTitleParametersFontUnderline			= 'fontUnderline';


	//
	// Connection
	//

	kESDSDKConnectSocketFunction				= 'connectElgatoStreamDeckSocket';
	kESDSDKRegisterPlugin						= 'registerPlugin';
	kESDSDKRegisterPropertyInspector			= 'registerPropertyInspector';
	kESDSDKPortParameter						= '-port';
	kESDSDKPluginUUIDParameter					= '-pluginUUID';
	kESDSDKRegisterEventParameter				= '-registerEvent';
	kESDSDKInfoParameter						= '-info';
	kESDSDKRegisterUUID							= 'uuid';

	kESDSDKApplicationInfo						= 'application';
	kESDSDKPluginInfo							= 'plugin';
	kESDSDKDevicesInfo							= 'devices';
	kESDSDKColorsInfo							= 'colors';
	kESDSDKDevicePixelRatio						= 'devicePixelRatio';

	kESDSDKApplicationInfoVersion				= 'version';
	kESDSDKApplicationInfoLanguage				= 'language';
	kESDSDKApplicationInfoPlatform				= 'platform';

	kESDSDKApplicationInfoPlatformMac			= 'mac';
	kESDSDKApplicationInfoPlatformWindows		= 'windows';

	kESDSDKColorsInfoHighlightColor					= 'highlightColor';
	kESDSDKColorsInfoMouseDownColor					= 'mouseDownColor';
	kESDSDKColorsInfoDisabledColor					= 'disabledColor';
	kESDSDKColorsInfoButtonPressedTextColor			= 'buttonPressedTextColor';
	kESDSDKColorsInfoButtonPressedBackgroundColor	= 'buttonPressedBackgroundColor';
	kESDSDKColorsInfoButtonMouseOverBackgroundColor	= 'buttonMouseOverBackgroundColor';
	kESDSDKColorsInfoButtonPressedBorderColor		= 'buttonPressedBorderColor';


type
	ESDSDKTarget = (kESDSDKTarget_HardwareAndSoftware = 0, kESDSDKTarget_HardwareOnly = 1, kESDSDKTarget_SoftwareOnly = 2);
	ESDSDKDeviceType = (kESDSDKDeviceType_StreamDeck = 0, kESDSDKDeviceType_StreamDeckMini = 1, kESDSDKDeviceType_StreamDeckXL = 2, kESDSDKDeviceType_StreamDeckMobile = 3);

implementation

begin
	
end.