//
//  ZoomSDKWindowController.m
//  ZoomSDKSample
//
//  Created by TOTTI on 31/08/2016.
//  Copyright © 2016 zoom.us. All rights reserved.
//

#import "ZoomSDKWindowController.h"
#import <ZoomSDK/ZoomSDK.h>

@interface ZoomSDKWindowController ()

@end

@implementation ZoomSDKWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (id)init
{
    if (self = [super initWithWindowNibName:@"ZoomSDKWindowController" owner:self]) {
        return self;
    }
    return nil;
}
- (void)windowWillClose:(NSNotification *)notification
{
    if([self.window.title isEqualToString:@"Share Camera"])
    {
        ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
        ZoomSDKASController* asController = [meetingService getASController];
        if(!asController)
            return;

        [asController stopShare];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ShowMeetingMainWindow" object:nil];
    }
}

@end
