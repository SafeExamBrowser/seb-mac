//
//  ZMSDKThumbnailView.h
//  ZoomSDKSample
//
//  Created by derain on 20/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ZMSDKThumbnailVideoItemView.h"

@class ZMSDKMeetingMainWindowController;

@interface ZMSDKThumbnailView : NSView
{
    NSButton*              _downArrowButton;
    NSButton*              _upArrowButton;
    ZMSDKThumbnailVideoItemView*  itemThumbnailView;
    NSMutableArray*        _thumbnailVideoArray;//All Video user array
    NSMutableArray*        _displayVideoArray;//diaplay Video user array
    ZMSDKMeetingMainWindowController* _meetingMainWindowController;
}

- (void)onUserJoin:(unsigned int)userID;
- (void)onUserleft:(unsigned int)userID;

- (void)onUserVideoStatusChange:(ZoomSDKVideoStatus)videoStatus UserID:(unsigned int)userID;
- (void)resetInfo;
- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController;
- (void)initThumbnialUserListArray;
@end
