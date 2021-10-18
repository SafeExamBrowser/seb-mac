//
//  ZMSDKConfUIMgr.m
//  ZoomSDKSample
//
//  Created by derain on 2018/12/5.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKConfUIMgr.h"
#import "ZoomSDKWindowController.h"
#import "ZMSDKCommonHelper.h"

static ZMSDKConfUIMgr* confUIMgr = nil;

@implementation ZMSDKConfUIMgr
- (id)init
{
    self = [super init];
    if (self)
    {
        if (!_meetingMainWindowController)
        {
            _meetingMainWindowController = [[ZMSDKMeetingMainWindowController alloc] init];
        }
        if (!_userHelper)
        {
            _userHelper = [[ZMSDKUserHelper alloc] initWithWindowController:_meetingMainWindowController];
        }
    }
    return self;
}
+ (void)initConfUIMgr
{
    if ( !confUIMgr ) {
        confUIMgr = [[ZMSDKConfUIMgr alloc] init];
    }
}
+ (void)uninitConfUIMgr
{
    if (confUIMgr)
    {
        confUIMgr = nil;
    }
}
+ (ZMSDKConfUIMgr*)sharedConfUIMgr
{
    if([ZMSDKCommonHelper sharedInstance].isUseCutomizeUI && !confUIMgr)
    {
        confUIMgr = [[ZMSDKConfUIMgr alloc] init];
    }
    return confUIMgr;
}

- (void)cleanUp
{
    if (_meetingMainWindowController)
    {
        [_meetingMainWindowController.window close];
        [_meetingMainWindowController cleanUp];
        _meetingMainWindowController = nil;
    }
    if (_userHelper)
    {
        _userHelper = nil;
    }
    return;
}

- (void)dealloc
{
    [self cleanUp];
}
- (void)createMeetingMainWindow
{
    if (!_meetingMainWindowController)
    {
        _meetingMainWindowController = [[ZMSDKMeetingMainWindowController alloc] init];
    }
    [_meetingMainWindowController.window setLevel:NSModalPanelWindowLevel];
    [_meetingMainWindowController.window makeKeyAndOrderFront:nil];
    [_meetingMainWindowController showWindow:nil];
    [_meetingMainWindowController updateUI];
}
- (ZMSDKUserHelper*)getUserHelper
{
    if (!_userHelper)
    {
        _userHelper = [[ZMSDKUserHelper alloc] initWithWindowController:_meetingMainWindowController];
    }
    return self.userHelper;
}
- (ZMSDKMeetingMainWindowController*)getMeetingMainWindowController
{
    return self.meetingMainWindowController;
}
- (int)getSystemVersion
{
    NSDictionary* sv = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString* versionString = [sv objectForKey:@"ProductVersion"];
    NSArray* array = [versionString componentsSeparatedByString:@"."];
    if(!array)
        return 0;
    if (array.count > 1)
    {
        versionString = [array objectAtIndex:1];
        int value = [versionString intValue];
        return value;
    }
    return 0;
}

@end
