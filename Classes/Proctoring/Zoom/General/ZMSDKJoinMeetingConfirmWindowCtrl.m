//

#import "ZMSDKJoinMeetingConfirmWindowCtrl.h"
@interface ZMSDKJoinMeetingConfirmWindowCtrl ()
@property (weak) IBOutlet NSTextField *meetingPsdTextField;
@property (strong, nonatomic) ZoomSDKJoinMeetingHelper *joinMeetingHelper;
@property (strong, nonatomic) ZoomSDKWebinarRegisterHelper *webinarRegisterHelper;
@property (weak) IBOutlet NSTextField *emailTextField;
@property (weak) IBOutlet NSTextField *userNameTextField;
@property (weak) IBOutlet NSTabView *tabView;

@end
@implementation ZMSDKJoinMeetingConfirmWindowCtrl

#pragma mark -- Public
- (void)showWebinarRegisterWindowWithRegisterHelper:(ZoomSDKWebinarRegisterHelper *)registerHelper {
    self.webinarRegisterHelper = registerHelper;
    if (registerHelper.getWebinarRegisterType == WebinarRegisterType_Email) {
        [self.window setLevel:NSPopUpMenuWindowLevel];
        [self.window makeKeyAndOrderFront:nil];
        [self.window center];
        [self.tabView selectTabViewItemWithIdentifier:@"webinarRegister"];
        self.emailTextField.stringValue = @"";
        self.userNameTextField.stringValue = @"";
    }
}
- (void)showRetryPasswordWindowWithJoinHelper:(ZoomSDKJoinMeetingHelper *)joinHelper {
    self.joinMeetingHelper = joinHelper;
    if (joinHelper.getReqInfoType != JoinMeetingReqInfoType_None) {
        [self.window setLevel:NSPopUpMenuWindowLevel];
        [self.window makeKeyAndOrderFront:nil];
        [self.window center];
        [self.tabView selectTabViewItemWithIdentifier:@"confirmPsd"];
        self.meetingPsdTextField.stringValue = @"";
    }
}
- (IBAction)onRetryPsdQuitBtnClick:(id)sender {
    if (self.joinMeetingHelper) {
        [self.joinMeetingHelper cancel];
    }
    [self.window close];
}
- (IBAction)onRetryPsdSubmitBtnClick:(id)sender {
    if (self.joinMeetingHelper) {
        [self.joinMeetingHelper inputPassword:_meetingPsdTextField.stringValue];
    }
    [self.window close];
}
- (IBAction)onWebinarRegisterQuitBtnClick:(id)sender {
    if (self.webinarRegisterHelper) {
        [self.webinarRegisterHelper cancel];
    }
    [self.window close];
}
- (IBAction)onWebinarRegisterSubmitBtnClick:(id)sender {
    if (self.webinarRegisterHelper) {
        [self.webinarRegisterHelper inputEmail:_emailTextField.stringValue screenName:_userNameTextField.stringValue];
    }
    [self.window close];
}


@end
