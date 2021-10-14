//
//  ZoomSDK.h
//  ZoomSDK
//
//  Created by TOTTI on 7/18/16.
//  Copyright (c) 2016 Zoom Video Communications, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//ZOOM SDK Errors
#import "ZoomSDKErrors.h"

//ZOOM SDK Authentication Service
#import "ZoomSDKAuthService.h"

//ZOOM SDK Meeting Service
#import "ZoomSDKMeetingService.h"

//ZOOM SDK Setting Service
#import "ZoomSDKSettingService.h"

//ZOOM SDK Pre-meeting Service
#import "ZoomSDKPremeetingService.h"

//ZOOM SDK Network Service
#import "ZoomSDKNetworkService.h"

//ZOOM SDK Custom Video UI
#import "ZoomSDKVideoContainer.h"

//ZOOM SDK Custom Share UI
#import "ZoomSDKShareContainer.h"
#import "ZoomSDKRawDataVideoSourceController.h"
#import "ZoomSDKRawDataController.h"
/**
 * Initialize the class to acquire all the services. 
 *
 * Access to the class and all the other components of the SDK by merging <ZoomSDK/ZoomSDK.h> into source code.
 */

typedef enum
{
    ZoomSDKLocale_Def = 0,
    ZoomSDKLocale_CN  = 1,
}ZoomSDKLocale;

@interface ZoomSDKInitParams : NSObject
{
    BOOL                        _needCustomizedUI;
    //Set whether to enable default log of which the capacity is less than 5M.
    BOOL                        _enableLog;
    //The size of the log file, the unit is MB. The size of log file is between 1 to 50M.
    int                         _logFileSize;
    //Set the locale of the App.
    ZoomSDKLocale               _appLocale;
    //After you re-sign the SDK, you should set the team identifier of your certificate, zoom will verify the certificate when loading. _teamIdentifier is subject.OU value of the signing certificate.
    NSString*                   _teamIdentifier;
    //Set the language of the App, usually if user does not specify the language, it will follow up the systematical language.
    NSString*                   _preferedLanguage;
    //Set custom localizable string file name, the default is under ZSDKRes.bundle/Contents/Resources/SDK_Localization_Resources.
    NSString*                   _customLocalizationFileName;
    //Set custom localizable string file path.
    NSString*                   _customLocalizationFilePath;
}
@property (assign, nonatomic) BOOL needCustomizedUI;
@property (assign, nonatomic) BOOL enableLog;
@property (assign, nonatomic) int logFileSize;
@property (assign, nonatomic) ZoomSDKLocale appLocale;
@property (retain, nonatomic) NSString *teamIdentifier;
@property (retain, nonatomic) NSString *preferedLanguage;
@property (retain, nonatomic) NSString *customLocalizationFileName;
@property (retain, nonatomic) NSString *customLocalizationFilePath;
/**
 * @brief Get the languages supported by the SDK.
 * @return The supported languages.
 */
- (NSArray*)getLanguageArray;
@end


@interface ZoomSDK : NSObject
{
    NSString               *_zoomDomain;
    ZoomSDKMeetingService  *_meetingService;
    ZoomSDKAuthService     *_authService;
    ZoomSDKSettingService  *_settingService;
    ZoomSDKPremeetingService *_premeetingService;
    ZoomSDKNetworkService    *_networkService;
    //BOOL                     _needCustomizedUI;
    ZoomSDKRawDataMemoryMode _videoRawDataMode;
    ZoomSDKRawDataMemoryMode _shareRawDataMode;
    ZoomSDKRawDataMemoryMode _audioRawDataMode;
}

@property (retain, nonatomic) NSString *zoomDomain;
//@property (assign, nonatomic) BOOL needCustomizedUI;
@property (assign, nonatomic) BOOL enableRawdataIntermediateMode;
@property (assign, nonatomic) ZoomSDKRawDataMemoryMode videoRawDataMode;
@property (assign, nonatomic) ZoomSDKRawDataMemoryMode shareRawDataMode;
@property (assign, nonatomic) ZoomSDKRawDataMemoryMode audioRawDataMode;
/**
 * @brief The sharedSDK will be instantiated only once over the lifespan of the application. Configure the client with the specified key and secret. 
 * @note Configure the client with the specified key and secret. 
 * @return A preconfigured ZOOM SDK client. 
 */
+ (ZoomSDK*)sharedSDK;

/**
* @brief This method is used to initialize Zoom SDK.
* @param initParams Specify the init  params.
*/
- (ZoomSDKError)initSDKWithParams:(ZoomSDKInitParams*)initParams NS_AVAILABLE_MAC(5.2);

/**
 * @brief This method is used to uninitialize Zoom SDK.
 */
- (void)unInitSDK;

/**
 * @brief Set client domain of ZOOM SDK.
 * @note The format of domain should like "zoom.us" or "www.zoom.us", please do not add the protocol "http" or "https".
 * @param domain A domain for starting/joining ZOOM meeting. 
 */
- (void)setZoomDomain:(NSString*)domain;
/**
 * @brief Get the default authentication service.
 * @note The ZOOM SDK can not be called unless the authentication service is called successfully. 
 * @return A preconfigured authentication service.
 */
- (ZoomSDKAuthService*)getAuthService;

/**
 * @brief Get the default meeting service.  
 * @return A preconfigured meeting Service
 */
- (ZoomSDKMeetingService*)getMeetingService;

/**
 * @brief Get the default meeting service.  
 * @return An object of setting service.
 */
- (ZoomSDKSettingService*)getSettingService;

/**
 * @brief Get the default pre-meeting service. 
 * @return An object of pre-meeting Service
 */
- (ZoomSDKPremeetingService*)getPremeetingService;

/**
 * @brief Get the default Network service.  
 * @return An object of Network Service
 */
- (ZoomSDKNetworkService*)getNetworkService;

/**
 * @brief Get object of controller ZoomSDKRawDataController.
 * @return If the function succeeds, it will return a ZoomSDKRawDataController object which you can use to handle raw data in meeting.
 */
- (ZoomSDKRawDataController*)getRawDataController;

/**
 * @brief Get the serial number of SDK version.
 * @return The default serial number of ZOOM SDK version.
 */
- (NSString*)getSDKVersionNumber;

/**
 * @brief Switch to the new domain of the App.
 * @param newDomain The new domain user want to switch to.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)switchDomain:(NSString*)newDomain force:(BOOL)force;

/**
 * @brief Set support dark model to the app.
 * @param isSupport YES means support dark model,NO is not support.
 * @note Support for Mac OS 10.14 and above
 * @note Call this interface in '- (void)applicationWillFinishLaunching:(NSNotification *)notification' in the App.
 */
- (ZoomSDKError)setSupportDarkModel:(BOOL)isSupport;

@end


