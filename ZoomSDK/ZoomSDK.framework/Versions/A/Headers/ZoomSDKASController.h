

#import "ZoomSDKErrors.h"
#import "ZoomSDKCustomizedAnnotationCtr.h"
#import "ZoomSDKShareContainer.h"
#import "ZoomSDKRemoteControllerHelper.h"
/**
 * @brief ZOOM UI annotation class.
 */
@interface ZoomSDKAnnotationController :NSObject
- (BOOL)isAnnotationDisable;
- (ZoomSDKError)setTool:(AnnotationToolType)type onScreen:(ScreenType)screen;
- (ZoomSDKError)clear:(AnnotationClearType)type onScreen:(ScreenType)screen;
- (ZoomSDKError)setColor:(float)red Green:(float)green Black:(float)black onScreen:(ScreenType)screen;
- (ZoomSDKError)setLineWidth:(long)lineWidth onScreen:(ScreenType)screen;
- (ZoomSDKError)undo:(ScreenType)screen;
- (ZoomSDKError)redo:(ScreenType)screen;

/**
 @brief Determine whether the legal notice for annotation is available.
 @return true indicates the legal notice for annotation transcript is available. Otherwise false.
 */
- (BOOL)isAnnotationLegalNoticeAvailable;

/**
 @brief Get the annotation legal notices prompt.
 @return If the function succeeds, it will return the annotation legal notices prompt. Otherwise nil.
 */
- (NSString *)getAnnotationLegalNoticesPrompt;

/**
 @brief Get the annotation legal notices explained.
 @return If the function succeeds, it will return the annotation legal notices explained. Otherwise nil.
 */
- (NSString *)getAnnotationLegalNoticesExplained;
@end

/**
 * @brief ZOOM share source class.
 */
@interface ZoomSDKShareSource :NSObject
{
    unsigned int _userID;
    BOOL  _isShowInFirstScreen;
    BOOL  _isShowInSecondScreen;
    BOOL  _canBeRemoteControl;
    
}
- (BOOL)isShowInFirstScreen;
- (BOOL)isShowInSecondScreen;
- (BOOL)canBeRemoteControl;
- (unsigned int)getUserID;
@end

/**
 * @brief ZOOM share information class.
 */
@interface ZoomSDKShareInfo: NSObject
{
    ZoomSDKShareContentType  _shareType;
    CGWindowID    _windowID; //Specify the APP that user wants to share. Available only for _shareType = ZoomSDKShareContentType_AS or ZoomSDKShareContentType_WB.
    CGDirectDisplayID  _displayID; //Specify the device screen on which that user wants to share the content. Available only for _shareType = ZoomSDKShareContentType_DS.
}
- (ZoomSDKShareContentType) getShareType;
/**
 * @brief Get the window ID of the shared APP.
 * @param windowID A pointer to CGWindowID.
 */
- (ZoomSDKError)getWindowID:(CGWindowID*)windowID;
 /**
 * @brief Get the display ID on which that user wants to share the content. 
 * @param displayID A pointer of CGDirectDisplayID.
 */
- (ZoomSDKError)getDisplayID:(CGDirectDisplayID*)displayID;

@end

 /**
  * @brief ZOOM SDK split screen information class.
  */
@interface ZoomSDKSplitScreenInfo : NSObject
{
    BOOL _isInSplitScreenMode;
    BOOL _isSupportSplitScreenMode;
}

-(BOOL)isInSplitScreenMode;
-(BOOL)isSupportSplitScreenMode;
@end

/**
 * @brief Callback of annotation events.
 */
@protocol ZoomSDKASControllerDelegate <NSObject>
@optional
/**
 * @brief Notification of the sharing status in the meeting.
 * @param status The sharing status.
 * @param userID The ID of user who is sharing.
 *
 */
- (void)onSharingStatus:(ZoomSDKShareStatus)status User:(unsigned int)userID;

/**
 * @brief Notification if the share is locked by host/co-host. 
 * @param shareLocked YES means the share is locked, otherwise not.
 */
- (void)onShareStatusLocked:(BOOL)shareLocked;

/**
 * @brief Notification of shared content is changed.
 * @param shareInfo The shared content, including window ID and monitor ID. 
 */
- (void)onShareContentChanged:(ZoomSDKShareInfo*)shareInfo;

/**
 * @brief Designated for Zoom Meeting notify the sharing user's has changed the viewer's annotation privilage.
 * @param isSupportAnnotation YES means the share source user enable viewer do annotate, otherwise not.
 * @param userID The user id that is sharing.
 */
- (void)onAnnotationSupportPropertyChanged:(BOOL)isSupportAnnotation shareSourceUserID:(unsigned int)userID;

/**
 * @brief Designated for Zoom Meeting notify the share Settings type changes.
 * @param type The share setting type.
 */
- (void)onShareSettingTypeChanged:(ZoomSDKShareSettingType)type;
@end


/**
 @brief ZOOM share controller.
 */
@interface ZoomSDKASController : NSObject
{
    id<ZoomSDKASControllerDelegate> _delegate;
    ZoomSDKShareContainer* _shareContainer;
    ZoomSDKAnnotationController* _annotationController;
    ZoomSDKCustomizedAnnotationCtr* _customizedAnnotationCtr;
    ZoomSDKRemoteControllerHelper*  _remoteControllerHelper;
}
@property(nonatomic, assign)id<ZoomSDKASControllerDelegate> delegate;

/**
 * @brief Start to share application. 
 * @param windowID The App window id to be shared.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)startAppShare:(CGWindowID)windowID;

/**
 * @brief Start to share desktop.
 * @param monitorID The ID of the monitor that you want to display the shared content.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)startMonitorShare:(CGDirectDisplayID)monitorID;

/**
 * @brief Stop the current share.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)stopShare;

/**
 * @brief Get the ID of users who are sharing. 
 * @return A NSArray of userID of all users who are sharing.
 */
- (NSArray*)getShareSourceList;

/**
 * @brief Choose the shared source with the specified user ID.
 * @param userID The ID of user who is sharing.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKShareSource*)getShareSourcebyUserId:(unsigned int)userID;

/**
 * @brief View the user's shared content on the screen by the specified user ID.
 * @param userID The ID of user that you want to view the shared content.
 * @param screen Select the screen where you want to view the shared content if you have more than one screen. 
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)viewShare:(unsigned int) userID onScreen:(ScreenType)screen;

/**
 * @brief Determine if it is able for user to start sharing. 
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)canStartShare;

/**
 * @brief Determine if the share is locked by the host/co-host. 
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isShareLocked;

/**
 * @brief Get the controller of annotation tools.
 * @return The object of ZoomSDKAnnotationController. 
 */
- (ZoomSDKAnnotationController*)getAnnotationController;

/**
 * @brief Get the controller of annotation tools used in user custom interface mode.
 * @return The object of ZoomSDKCustomizedAnnotationCtr. 
 */
- (ZoomSDKCustomizedAnnotationCtr*)getCustomizedAnnotationCtr;

/**
 * @brief Get custom share container. 
 * @return If the function succeeds, it will return the object of ZoomSDKShareContainer, otherwise not.
 */
- (ZoomSDKShareContainer*)getShareContainer;

/**
 * @brief Get the class object of ZoomSDKRemoteControllerHelper.
 * @return If the function succeeds, it will return the object of ZoomSDKRemoteControllerHelper, otherwise not. 
 */
- (ZoomSDKRemoteControllerHelper*)getRemoteControllerHelper;

/**
 * @brief Start annotation.
 * @param position The position of annotation toolbar. 
 * @param screen Specify the view where you want to place the annotation toolbar. 
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)startAnnotation:(NSPoint)position onScreen:(ScreenType)screen;

/**
 * @brief Stop annotation.
 * @param screen Specify the view on which you want to stop annotating. 
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)stopAnnotation:(ScreenType)screen;

/**
 * @brief Get the user ID of current remote controller. 
 * @param userID The ID of user who can remotely control others.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)getCurrentRemoteController:(unsigned int*)userID;

/**
 * @brief Get the information of split screen when viewing the share in the meeting.
 */
- (ZoomSDKSplitScreenInfo*)getCurrentSplitScreenModeInfo;

/**
 * @brief Switch to split screen mode, which means that the shared content and the video are separated in different column, the video won't cover the shared content.
 * @param switchTo YES means to enable side by side mode, otherwise not.
 */
-(ZoomSDKError)switchSplitScreenMode:(BOOL)switchTo;

/**
 * @brief Clean up as-controller object.
 */
- (void)cleanUp;

/**
 * @brief Share white-board.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)startWhiteBoardShare;

/**
 * @brief Start sharing a portion of screen by a frame. User can resize the shared range during sharing.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)startFrameShare;

/**
 * @brief Share audio.
 * @return If the function succeeds, it will return ZoomSDKError_Success, otherwise failed.
 */
- (ZoomSDKError)startAudioShare;

/**
 * @brief Share camera.
 * @param deviceID The ID of camera to be shared.
 * @param window The view on which you want to show camera content. If you want to user ZOOM UI, set it to nil. 
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)startShareCamera:(NSString*)deviceID displayWindow:(NSWindow*)window;

/**
 * @brief Determine if user can share next camera, only avaliable for ZOOM UI.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)canSwitchToShareNextCamera;
/**
 * @brief Share next camera, only avaliable for ZOOM UI.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 */
- (ZoomSDKError)switchToShareNextCamera;

/**
 * @brief Determine if user can share white-board.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isAbleToShareWhiteBoard;
/**
 * @brief Determine if user can share a potion of screen.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isAbleToShareFrame;
/**
 * @brief Determine if user can share computer audio.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isAbleToShareComputerAudio;
/**
 * @brief Determine if user can share camera.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isAbleToShareCamera;

/**
 * @brief This method is used for the sharing user to disable/enable viewer's privilege of annotation.
 * @param screenType Select the screen where you want to operate on.
 * @param disable YES means disable viewer's annotation privilege, NO means enable.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)disableViewerAnnotation:(ScreenType)screenType disable:(BOOL)disable;

/**
 * @brief Determine whether the viewer's annotate privilege is locked.
 * @param screenType Select the screen where you want to operate on.
 * @param locked A point to A BOOL, if function call successfully, the value of 'locked' means whether viewer's annotate privilege is locked, YES means viewer's annotate privilege is locked.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)isViewerAnnotationLocked:(ScreenType)screenType isLocked:(BOOL*)locked;

/**
 * @brief Determine if it is able for user to disable viewer's annotation privilege.
 * @param screenType Select the screen where you want to operate on.
 * @param canDisable A point to A BOOL, if function call successfully, the value of 'canDisable' means whether the user can disable viewer's annotation, YES means can disable, NO means cannot.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)canDisableViewerAnnotation:(ScreenType)screenType canDisabled:(BOOL*)canDisable;

/**
 * @brief Determine if it is able for user to do annotation.
 * @param screenType Select the screen where you want to operate on.
 * @param canAnnotate A point to A BOOL, if function call successfully, the value of 'canAnnotate' means whether the user can do annotation, YES means can do annotation, NO means cannot.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)canDoAnnotation:(ScreenType)screenType canAnnotate:(BOOL*)canAnnotate;

/**
 * @brief Determine if support enable or disable optimizing for full screen video clip.
 * @return If support, it will return YES, otherwise not.
 */
- (BOOL)isSupportEnableOptimizeForFullScreenVideoClip;

/**
 * @brief Determine if share computer sound option is on or off.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isEnableShareComputerSoundOn;

/**
 * @brief Determine if optimizing for full screen video clip option is on or off.
 * @return If the function succeeds, it will return YES, otherwise not.
 */
- (BOOL)isEnableOptimizeForFullScreenVideoClipOn;

/**
 * @brief Determine enable share computer sound.
 * @param enable Enable or disable share computer sound.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)enableShareComputerSound:(BOOL)enable;

/**
 * @brief Determine enable optimizing for full screen video clip.
 * @param enable Enable or disable optimizing for full screen video clip.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)enableOptimizingScreenShareForVideoClip:(BOOL)enable;

/**
 * @brief Determine enable share computer sound when shaing.
 * @param enable Enable or disable share computer sound.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)enableShareComputerSoundWhenSharing:(BOOL)enable;

/**
 * @brief Determine enable optimizing for full screen video clip when shaing.
 * @param enable Enable or disable optimizing for full screen video clip.
 * @return A ZoomSDKError to tell client function call successful or not.
 */
- (ZoomSDKError)enableOptimizingScreenShareForVideoClipWhenSharing:(BOOL)enable;

/**
 @brief Determine whether the legal notice for whiteboard is available.
 @return true indicates the legal notice for whiteboard is available. Otherwise false.
 */
- (BOOL)isWhiteboardLegalNoticeAvailable;

/**
 @brief Get the whiteboard legal notices prompt.
 @return If the function succeeds, it will return the whiteboard legal notices prompt. Otherwise nil.
 */
- (NSString *)getWhiteboardLegalNoticesPrompt;

/**
 @brief Get the whiteboard legal notices explained.
 @return If the function succeeds, it will return the whiteboard legal notices explained. Otherwise nil.
 */
- (NSString *)getWhiteboardLegalNoticesExplained;
@end


