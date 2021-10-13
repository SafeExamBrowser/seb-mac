//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>
#import "ZMSDKMeetingMainWindowController.h"
NS_ASSUME_NONNULL_BEGIN

@interface ZMSDKChatWindowController : NSWindowController
@property (strong,nonatomic) ZMSDKMeetingMainWindowController *meetingMainWindowController;
- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController;

- (void)onChatMessageNotification:(ZoomSDKChatInfo*)chatInfo;
@end

NS_ASSUME_NONNULL_END
