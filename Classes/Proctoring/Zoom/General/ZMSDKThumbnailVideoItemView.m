//
//  ZMSDKThumbnailVideoItemView.m
//  ZoomSDKSample
//
//  Created by derain on 12/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKThumbnailVideoItemView.h"

const int kZMSDKBaseViewThinFrameOffset = 0;

@interface ZMSDKThumbnailVideoItemView()
- (NSRect)getVideoRectFromViewFrame:(NSRect)viewFrame;
@end


@implementation ZMSDKThumbnailVideoItemView

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];
}
- (id)initWithFrame:(NSRect)frame userID:(unsigned int)userID
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.userID = userID;
        _videoItem = nil;
        return self;
    }
    return nil;
}

- (BOOL)canBecomeKeyView
{
    return NO;
}

- (void)creatVideoElementViewItem
{
    if(!_videoItem)
    {
        ZoomSDKNormalVideoElement* tempVideoItem = [[ZoomSDKNormalVideoElement alloc] initWithFrame:self.bounds];
        ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
        [videoContainer createVideoElement:&tempVideoItem];
        self.videoItem = tempVideoItem;
        [self addSubview:[_videoItem getVideoView]];
    }
}
- (void)removeVideoElementViewItem
{
    if(_videoItem)
    {
        ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
        [videoContainer cleanVideoElement:_videoItem];
        NSView* videoview = [_videoItem getVideoView];
        [videoview removeFromSuperview];
        _videoItem = nil;
    }
}
- (void)cleanup
{
    if(_videoItem)
    {
        ZoomSDKVideoContainer* videoContainer = [[[ZoomSDK sharedSDK] getMeetingService] getVideoContainer];
        [videoContainer cleanVideoElement:_videoItem];
        NSView* videoview = [_videoItem getVideoView];
        [videoview removeFromSuperview];
        _videoItem = nil;
    }
    while(self.subviews.count>0)
    {
        NSView* theView = [self.subviews objectAtIndex:0];
        if(theView && [theView isKindOfClass:[NSButton class]])
        {
            NSButton* theButton = (NSButton*)theView;
            theButton.target = nil;
            theButton.action = nil;
        }
        if(theView && theView.superview)
            [theView removeFromSuperview];
    }
}
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self cleanup];
}

- (NSRect)getVideoRectFromViewFrame:(NSRect)viewFrame
{
    NSRect rcVideo = viewFrame;
    int frameOffset = 0;
    rcVideo.origin.x = frameOffset;
    rcVideo.origin.y = frameOffset;
    rcVideo.size.width -= frameOffset * 2;
    rcVideo.size.height -= frameOffset * 2;
    return rcVideo;
}

- (void)refreshRender
{
    int userID = self.userID;
    [self setUserID:userID];
}

- (ZoomSDKNormalVideoElement*)getVideoItem
{
    return _videoItem;
}
@end
