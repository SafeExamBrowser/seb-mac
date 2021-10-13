//
//  ZMSDKJoinMeetingWindowController.h
//  ZoomSDKSample
//
//  Created by derain on 2018/11/28.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMSDKMainWindowController.h"

@interface ZMSDKJoinMeetingWindowController : NSWindowController
{
    IBOutlet NSTextField* _meetingNumberTextField;
    IBOutlet NSTextField* _meetingPswTextField;
    IBOutlet NSTextField* _displayNameTextField;
    IBOutlet NSButton* _joinButton;
}

- (id)initWithMgr:(ZMSDKMainWindowController*)mainWindowController;
- (IBAction)onJoinButtonClicked:(id)sender;
- (void)showSelf;

@end
