//
//  ZMSDKThumbnailView.m
//  ZoomSDKSample
//
//  Created by derain on 20/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import "ZMSDKThumbnailView.h"
#import "ZMSDKMeetingMainWindowController.h"

@implementation ZMSDKThumbnailView

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        _thumbnailVideoArray = [[NSMutableArray alloc] init];
        _displayVideoArray = [[NSMutableArray alloc] init];
        [self initUI];
    }
    return self;
}
- (void)awakeFromNib
{
    [self initUI];
}
- (void)dealloc
{
    [self cleanUp];
}
- (void)cleanUp
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if(_thumbnailVideoArray)
    {
        for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _thumbnailVideoArray)
        {
            [thumbnailVideoView removeVideoElementViewItem];
            if(thumbnailVideoView.superview)
                [thumbnailVideoView removeFromSuperview];
            [_thumbnailVideoArray removeObject:thumbnailVideoView];
        }
        [_thumbnailVideoArray removeAllObjects];
        _thumbnailVideoArray = nil;
    }
    if(_displayVideoArray)
    {
        for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _displayVideoArray)
        {
            [thumbnailVideoView removeVideoElementViewItem];
            if(thumbnailVideoView.superview)
                [thumbnailVideoView removeFromSuperview];
            [_displayVideoArray removeObject:thumbnailVideoView];
        }
        [_displayVideoArray removeAllObjects];
        _displayVideoArray = nil;
    }
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSBezierPath* thePath = [NSBezierPath bezierPathWithRect:self.bounds];
    [[NSColor blackColor] set];
    [thePath fill];
    /*thePath.lineWidth = 5;
    [[NSColor greenColor] set];
    [thePath stroke];*/
}
- (void)initUI
{
    [self initArrowButton];
}

- (void)onUserJoin:(unsigned int)userID
{
    return;
}
- (void)relayoutThumbnailVideoUI
{
    NSUInteger count = _displayVideoArray.count;
    if(count > 0)
    {
        switch (count) {
            case 1:
            {
                ZMSDKThumbnailVideoItemView* thumbnailVideoView = (ZMSDKThumbnailVideoItemView*)[_displayVideoArray objectAtIndex:0];
                [thumbnailVideoView setFrameOrigin:NSMakePoint(0, (self.frame.size.height - thumbnailVideoView.frame.size.height)/2)];
                if(![thumbnailVideoView getVideoItem])
                {
                    [self addSubview:thumbnailVideoView];
                    [thumbnailVideoView creatVideoElementViewItem];
                    [thumbnailVideoView getVideoItem].userid = thumbnailVideoView.userID;
                }
            }
                break;
            case 2:
            {
                ZMSDKThumbnailVideoItemView* thumbnailVideoView1 = (ZMSDKThumbnailVideoItemView*)[_displayVideoArray objectAtIndex:1];
                ZMSDKThumbnailVideoItemView* thumbnailVideoView2 = (ZMSDKThumbnailVideoItemView*)[_displayVideoArray objectAtIndex:0];
                [thumbnailVideoView1 setFrameOrigin:NSMakePoint(0, (self.frame.size.height - thumbnailVideoView1.frame.size.height*2)/2)];
                [thumbnailVideoView2 setFrameOrigin:NSMakePoint(0, (thumbnailVideoView1.frame.origin.y + thumbnailVideoView1.frame.size.height))];
                
                if(![thumbnailVideoView1 getVideoItem])
                {
                    [self addSubview:thumbnailVideoView1];
                    [thumbnailVideoView1 creatVideoElementViewItem];
                    [thumbnailVideoView1 getVideoItem].userid = thumbnailVideoView1.userID;
                }
                
                if(![thumbnailVideoView2 getVideoItem])
                {
                    [self addSubview:thumbnailVideoView2];
                    [thumbnailVideoView2 creatVideoElementViewItem];
                    [thumbnailVideoView2 getVideoItem].userid = thumbnailVideoView2.userID;
                }
            }
                break;
            case 3:
            {
                int i = 0;
                //for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _displayVideoArray)
                for(int j = (int)_displayVideoArray.count-1; j >= 0; j--)
                {
                    ZMSDKThumbnailVideoItemView* thumbnailVideoView = [_displayVideoArray objectAtIndex:i];
                    [thumbnailVideoView setFrameOrigin:NSMakePoint(0, (self.frame.size.height - thumbnailVideoView.frame.size.height*3)/2 + thumbnailVideoView.frame.size.height*i)];
                    
                    if(![thumbnailVideoView getVideoItem])
                    {
                        [self addSubview:thumbnailVideoView];
                        [thumbnailVideoView creatVideoElementViewItem];
                        [thumbnailVideoView getVideoItem].userid = thumbnailVideoView.userID;
                    }
                    i++;
                }
            }
                break;
            default:
                break;
        }
    }
    [self updateArrowButton];
}
- (void)setMeetingMainWindowController:(ZMSDKMeetingMainWindowController*)meetingMainWindowController
{
    _meetingMainWindowController = meetingMainWindowController;
}
- (void)onUserleft:(unsigned int)userID
{
    ZMSDKThumbnailVideoItemView *thumbnailVideoView = nil;
    int index = -1;
    for(ZMSDKThumbnailVideoItemView* item in _thumbnailVideoArray)
    {
        if(item.userID == userID)
        {
            thumbnailVideoView = item;
            index = (int)[_thumbnailVideoArray indexOfObject:item];
        }
    }
    if(thumbnailVideoView)
    {
        [thumbnailVideoView removeVideoElementViewItem];
        if(thumbnailVideoView.superview)
            [thumbnailVideoView removeFromSuperview];
        [_thumbnailVideoArray removeObject:thumbnailVideoView];
        thumbnailVideoView = nil;
    }
    else
    {
        return;
    }
    
    ZMSDKThumbnailVideoItemView *displayThumbnailVideoView = nil;
    for(ZMSDKThumbnailVideoItemView* item in _displayVideoArray)
    {
        if(item.userID == userID)
        {
            displayThumbnailVideoView = item;
        }
    }
    if(displayThumbnailVideoView)
    {
        [displayThumbnailVideoView removeVideoElementViewItem];
        if(displayThumbnailVideoView.superview)
            [displayThumbnailVideoView removeFromSuperview];
        [_displayVideoArray removeObject:displayThumbnailVideoView];
        displayThumbnailVideoView = nil;
        
        if(_displayVideoArray.count == 0)
        {
            if(index - 3 >= 0)
            {
                NSArray* newDisArray = [_thumbnailVideoArray subarrayWithRange:NSMakeRange(index - 3, 3)];
                for(ZMSDKThumbnailVideoItemView* item in newDisArray)
                {
                    ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width,200) userID:item.userID];
                    [_displayVideoArray addObject:thumbnailVideoView];
                }
            }
            [self relayoutThumbnailVideoUI];
            return;
        }
        
        ZMSDKThumbnailVideoItemView *displayThumbnailVideoView = [_displayVideoArray objectAtIndex:(_displayVideoArray.count - 1)];
        int index = [self getUserVideoViewIndexById:displayThumbnailVideoView.userID inArray:_thumbnailVideoArray];
        
        if((_thumbnailVideoArray.count != _displayVideoArray.count) && (_thumbnailVideoArray.count >= index + 2))
        {
            ZMSDKThumbnailVideoItemView* item = [_thumbnailVideoArray objectAtIndex:index + 1];
            if(item.userID > 0)
            {
                BOOL hasExist = NO;
                for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _displayVideoArray)
                {
                    if (thumbnailVideoView.userID == userID)
                    {
                        hasExist = YES;
                    }
                }
                if(!hasExist)
                {
                    ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width,200) userID:item.userID];
                    [_displayVideoArray addObject:thumbnailVideoView];
                }
            }
        }
        [self relayoutThumbnailVideoUI];
    }
    else
    {
        if(_displayVideoArray.count == 0)
            return;
        if(_displayVideoArray.count == 1)
        {
            displayThumbnailVideoView = [_displayVideoArray objectAtIndex:0];
            int index = [self getUserVideoViewIndexById:displayThumbnailVideoView.userID inArray:_thumbnailVideoArray];
            if(index - 2 >= 0)
            {
                [displayThumbnailVideoView removeVideoElementViewItem];
                if(displayThumbnailVideoView.superview)
                    [displayThumbnailVideoView removeFromSuperview];
                [_displayVideoArray removeObject:displayThumbnailVideoView];
                displayThumbnailVideoView = nil;
                
                NSArray* newDisArray = [_thumbnailVideoArray subarrayWithRange:NSMakeRange(index - 2, 3)];
                for(ZMSDKThumbnailVideoItemView* item in newDisArray)
                {
                    ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width,200) userID:item.userID];
                    [_displayVideoArray addObject:thumbnailVideoView];
                }
            }
            [self relayoutThumbnailVideoUI];
            return;
        }
        ZMSDKThumbnailVideoItemView *displayThumbnailVideoView = [_displayVideoArray objectAtIndex:(_displayVideoArray.count - 1)];
        int itemIndex = [self getUserVideoViewIndexById:displayThumbnailVideoView.userID inArray:_thumbnailVideoArray];
        if(index < itemIndex)
        {
            displayThumbnailVideoView = [_displayVideoArray objectAtIndex:0];
            [displayThumbnailVideoView removeVideoElementViewItem];
            if(displayThumbnailVideoView.superview)
                [displayThumbnailVideoView removeFromSuperview];
            [_displayVideoArray removeObject:displayThumbnailVideoView];
            displayThumbnailVideoView = nil;
            
            if(_thumbnailVideoArray.count >= itemIndex + 2)
            {
                ZMSDKThumbnailVideoItemView * addedDisplayThumbnailVideoView = [_thumbnailVideoArray objectAtIndex:itemIndex+1];
                ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width,200) userID:addedDisplayThumbnailVideoView.userID];
                [_displayVideoArray addObject:thumbnailVideoView];
            }
            [self relayoutThumbnailVideoUI];
        }
    }
    [self updateArrowButton];
}
- (void)onUserVideoStatusChange:(ZoomSDKVideoStatus)videoStatus UserID:(unsigned int)userID
{
    BOOL hasExist = NO;
    for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _thumbnailVideoArray)
    {
        if (thumbnailVideoView.userID == userID)
        {
            hasExist = YES;
        }
    }
    if(!hasExist)
    {
        ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 200) userID:userID];
        [_thumbnailVideoArray addObject:thumbnailVideoView];
    }
    BOOL displayViewHasExist = NO;
    for(ZMSDKThumbnailVideoItemView* thumbnailVideoView in _displayVideoArray)
    {
        if (thumbnailVideoView.userID == userID)
        {
            displayViewHasExist = YES;
        }
    }
    if(!displayViewHasExist && !hasExist)
    {
        if(_displayVideoArray.count < 3)
        {
            ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 200) userID:userID];
            [_displayVideoArray addObject:thumbnailVideoView];
        }
        [self relayoutThumbnailVideoUI];
    }
}
- (void)initThumbnialUserListArray
{
    NSArray* userList = [[[[ZoomSDK sharedSDK] getMeetingService] getMeetingActionController] getParticipantsList];
    if(!_thumbnailVideoArray)
    {
        _thumbnailVideoArray = [[NSMutableArray alloc] init];
    }
    if(_thumbnailVideoArray.count > 0)
    {
        [_thumbnailVideoArray removeAllObjects];
    }
    if(!_displayVideoArray)
    {
        _displayVideoArray = [[NSMutableArray alloc] init];
    }
    if(_displayVideoArray.count > 0)
    {
        [_displayVideoArray removeAllObjects];
    }
    
    if(userList && userList.count > 0)
    {
        for(NSNumber* userID in userList)
        {
            ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 200) userID:userID.unsignedIntValue];
            [_thumbnailVideoArray addObject:thumbnailVideoView];
            
            if(_displayVideoArray.count < 3)
            {
                ZMSDKThumbnailVideoItemView* thumbnailDisplayVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, self.frame.size.width, 200) userID:userID.unsignedIntValue];
                [_displayVideoArray addObject:thumbnailDisplayVideoView];
            }
        }
        [self relayoutThumbnailVideoUI];
    }
}
- (void)resetInfo
{
    if(_thumbnailVideoArray)
    {
        ZMSDKThumbnailVideoItemView *thumbnailVideoView = nil;
        for(int i = (int)_thumbnailVideoArray.count - 1; i >= 0; i--)
        {
            thumbnailVideoView = [_thumbnailVideoArray objectAtIndex:i];
            if(thumbnailVideoView)
            {
                [thumbnailVideoView removeVideoElementViewItem];
                if(thumbnailVideoView.superview)
                    [thumbnailVideoView removeFromSuperview];
                [_thumbnailVideoArray removeObjectAtIndex:i];
                thumbnailVideoView = nil;
            }
        }
        [_thumbnailVideoArray removeAllObjects];
    }
    if(_displayVideoArray)
    {
        ZMSDKThumbnailVideoItemView *thumbnailVideoView = nil;
        for(int i = (int)_displayVideoArray.count - 1; i >= 0; i--)
        {
            thumbnailVideoView = [_displayVideoArray objectAtIndex:i];
            if(thumbnailVideoView)
            {
                [thumbnailVideoView removeVideoElementViewItem];
                if(thumbnailVideoView.superview)
                    [thumbnailVideoView removeFromSuperview];
                [_displayVideoArray removeObjectAtIndex:i];
                thumbnailVideoView = nil;
            }
        }
        [_displayVideoArray removeAllObjects];
    }
}
- (BOOL)isUserAlreadyExist:(unsigned int)inUserId inArray:(NSArray*)inArray
{
    if(!inArray || inArray.count<=0)
        return NO;
    for(ZMSDKThumbnailVideoItemView* item in inArray)
    {
        if(item.userID == inUserId)
            return YES;
    }
    return NO;
}
- (ZMSDKThumbnailVideoItemView*)getUserVideoViewById:(unsigned int)userID inArray:(NSArray<ZMSDKThumbnailVideoItemView*>*)inArray
{
    if(index<0 || !inArray || !userID)
        return nil;
    for(ZMSDKThumbnailVideoItemView* item in inArray)
    {
        unsigned int userid = item.userID;
        if(userid == userID)
            return item;
    }
    return nil;
}
- (int)getUserVideoViewIndexById:(unsigned int)userID inArray:(NSArray<ZMSDKThumbnailVideoItemView*>*)inArray
{
    if(inArray.count == 0 || !inArray || !userID)
        return -1;
    for(int i = 0; i < inArray.count; i++)
    {
        unsigned int userid = [inArray objectAtIndex:i].userID;
        if(userid == userID)
            return i;
    }
    return -1;
}

- (void)updateArrowButton
{
    if(_thumbnailVideoArray.count > 3)
     {
         if(_displayVideoArray.count > 0 && _thumbnailVideoArray.count > 0)
         {
             ZMSDKThumbnailVideoItemView* videoView = [_thumbnailVideoArray objectAtIndex:0];
             ZMSDKThumbnailVideoItemView* displayVideoView = [_displayVideoArray objectAtIndex:0];
     
             ZMSDKThumbnailVideoItemView* lastVideoView = [_thumbnailVideoArray objectAtIndex:(_thumbnailVideoArray.count - 1)];
             ZMSDKThumbnailVideoItemView* lastDisplayVideoView = [_displayVideoArray objectAtIndex:(_displayVideoArray.count - 1)];
             
             if((videoView.userID == displayVideoView.userID) && (lastVideoView.userID != lastDisplayVideoView.userID))
             {
                 [_upArrowButton setHidden:YES];
                 [_downArrowButton setHidden:NO];
             }
             else if((videoView.userID != displayVideoView.userID) && (lastVideoView.userID == lastDisplayVideoView.userID))
             {
                 [_upArrowButton setHidden:NO];
                 [_downArrowButton setHidden:YES];
             }
             else if((videoView.userID != displayVideoView.userID) && (lastVideoView.userID != lastDisplayVideoView.userID))
             {
                 [_upArrowButton setHidden:NO];
                 [_downArrowButton setHidden:NO];
             }
             else
             {
                 [_upArrowButton setHidden:YES];
                 [_downArrowButton setHidden:YES];
             }
         }
         return;
     }
     [_upArrowButton setHidden:YES];
     [_downArrowButton setHidden:YES];
}
- (void)initArrowButton
{
     float marigin = 5;
     if(!_downArrowButton)
     {
        _downArrowButton = [[NSButton alloc] initWithFrame:NSMakeRect((self.frame.size.width - _upArrowButton.frame.size.width)/2, marigin, 30, 30)];
        _downArrowButton.image = [NSImage imageNamed:@"plistArrowBottom"];
        _downArrowButton.imagePosition = NSImageOnly;
        _downArrowButton.imageScaling = NSImageScaleProportionallyUpOrDown;
        _downArrowButton.bezelStyle = NSBezelStyleRoundRect;
        
        [_downArrowButton setHidden:YES];
        _downArrowButton.target = self;
        _downArrowButton.action = @selector(onDownArrowClicked:);
        [self addSubview:_downArrowButton];
     }
     if(!_upArrowButton)
     {
         _upArrowButton = [[NSButton alloc] initWithFrame:NSMakeRect((self.frame.size.width - _upArrowButton.frame.size.width)/2, self.frame.size.height - marigin - 30, 30, 30)];
         _upArrowButton.image = [NSImage imageNamed:@"plistArrowTop"];
         _upArrowButton.imagePosition = NSImageOnly;
         _upArrowButton.imageScaling = NSImageScaleProportionallyUpOrDown;
         _upArrowButton.bezelStyle = NSBezelStyleRoundRect;
         
         [_upArrowButton setHidden:YES];
         _upArrowButton.target = self;
         _upArrowButton.action = @selector(onUpArrowClicked:);
         [self addSubview:_upArrowButton];
     }
}
- (void)onDownArrowClicked:(id)sender
{
    if(!_displayVideoArray || !_thumbnailVideoArray || _displayVideoArray.count <= 0)
        return;
     ZMSDKThumbnailVideoItemView* displayLastView = [_displayVideoArray objectAtIndex:(_displayVideoArray.count - 1)];
     for (ZMSDKThumbnailVideoItemView* itemView in _thumbnailVideoArray)
     {
         if (itemView.userID == displayLastView.userID)
         {
             NSUInteger index = [_thumbnailVideoArray indexOfObject:itemView];
             index = index + 1;
             NSArray* newDisplayArray = [_thumbnailVideoArray subarrayWithRange:NSMakeRange(index, _thumbnailVideoArray.count - index)];
             
             for(int i = (int)_displayVideoArray.count - 1; i >= 0; i--)
             {
                 ZMSDKThumbnailVideoItemView* videoView = [_displayVideoArray objectAtIndex:i];
                 [videoView removeVideoElementViewItem];
                 if(videoView.superview)
                     [videoView removeFromSuperview];
                 [_displayVideoArray removeObjectAtIndex:i];
                 videoView = nil;
             }
             
             NSMutableArray* displayArray = [NSMutableArray arrayWithArray:newDisplayArray];
             if(displayArray.count > 3)
             {
                 displayArray = (NSMutableArray*)[_thumbnailVideoArray subarrayWithRange:NSMakeRange(index, 3)];
             }
             for(ZMSDKThumbnailVideoItemView* item in displayArray)
             {
                 if(item.userID > 0)
                 {
                     ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200) userID:item.userID];
                     [_displayVideoArray addObject:thumbnailVideoView];
                 }
             }
         }
     }
     [self relayoutThumbnailVideoUI];
}

- (void)onUpArrowClicked:(id)sender
{
    if(!_displayVideoArray || !_thumbnailVideoArray || _displayVideoArray.count <= 0)
        return;
     ZMSDKThumbnailVideoItemView* displayLastView = [_displayVideoArray objectAtIndex:0];
     for (ZMSDKThumbnailVideoItemView* itemView in _thumbnailVideoArray)
     {
         if (itemView.userID == displayLastView.userID)
         {
             NSUInteger index = [_thumbnailVideoArray indexOfObject:itemView];
             NSArray* newDisplayArray = nil;
             if(index >= 3)
             {
                 newDisplayArray = [_thumbnailVideoArray subarrayWithRange:NSMakeRange(index - 3, 3)];
             }
             else
             {
                 newDisplayArray = [_thumbnailVideoArray subarrayWithRange:NSMakeRange(0, index)];
             }
             
             for(int i = (int)_displayVideoArray.count - 1; i >= 0; i--)
             {
                 ZMSDKThumbnailVideoItemView* videoView = [_displayVideoArray objectAtIndex:i];
                 [videoView removeVideoElementViewItem];
                 if(videoView.superview)
                     [videoView removeFromSuperview];
                 [_displayVideoArray removeObjectAtIndex:i];
                 videoView = nil;
             }
             
             NSMutableArray* displayArray = [NSMutableArray arrayWithArray:newDisplayArray];
             for(ZMSDKThumbnailVideoItemView* item in displayArray)
             {
                 if(item.userID > 0)
                 {
                     ZMSDKThumbnailVideoItemView* thumbnailVideoView= [[ZMSDKThumbnailVideoItemView alloc] initWithFrame:NSMakeRect(0, 0, 320, 200) userID:item.userID];
                     [_displayVideoArray addObject:thumbnailVideoView];
                 }
             }
         }
    }
    [self relayoutThumbnailVideoUI];
}
@end
