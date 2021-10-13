//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKMeetingMainWindowController.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZMSDKJoinMeetingConfirmWindowCtrl : NSWindowController
- (void)showWebinarRegisterWindowWithRegisterHelper:(ZoomSDKWebinarRegisterHelper *)registerHelper;
- (void)showRetryPasswordWindowWithJoinHelper:(ZoomSDKJoinMeetingHelper *)joinHelper;
@end

NS_ASSUME_NONNULL_END
