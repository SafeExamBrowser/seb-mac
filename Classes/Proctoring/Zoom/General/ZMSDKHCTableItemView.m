//
//  ZMSDKHCTableItemView.m
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import "ZMSDKHCTableItemView.h"
#import "ZMSDKRoundImageView.h"
#import <ZoomSDK/ZoomSDK.h>

typedef NS_ENUM(NSUInteger, ZMSDKHCTableItemIconTag)
{
    ZMSDKHCITEM_TAG_ICON_AVATAR,
    ZMSDKHCITEM_TAG_NAME,
};

@implementation ZMSDKHCTableItemView

- (id)initWithFrame:(NSRect)frameRect{
    self = [super initWithFrame:frameRect];
    if(self)
    {
        [self initUI];
    }
    return self;
}
- (void)awakeFromNib{
    [self initUI];
}
- (void)dealloc{
    [self cleanUp];
}
- (void)cleanUp{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    //remove subViews
    [self removeViewWithTag:ZMSDKHCITEM_TAG_ICON_AVATAR];
    [self removeViewWithTag:ZMSDKHCITEM_TAG_NAME];
}
- (void)removeViewWithTag:(NSInteger)tag{
    NSView* theView = [self viewWithTag:tag];
    if(theView){
        if([theView respondsToSelector:@selector(cleanup)])
            [theView performSelector:@selector(cleanup)];
        if([theView superview])
            [theView removeFromSuperview];
    }
    theView = nil;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Drawing code here.
}
- (void)initUI{
    float width = 10;
    float height = 10;
    
    width = 30;
    height = 30;
    //avatar Icon
    ZMSDKRoundImageView* avatarImageView = [[ZMSDKRoundImageView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    if(avatarImageView)
    {
        avatarImageView.tag = ZMSDKHCITEM_TAG_ICON_AVATAR;
        avatarImageView.isRound = YES;
        [avatarImageView setHidden:YES];
        avatarImageView.autoresizingMask = NSViewMaxXMargin|NSViewMinYMargin|NSViewMaxYMargin;
        [self addSubview:avatarImageView];
        
        avatarImageView = nil;
    }
    
    width = 30;
    height = 16;
    //name text field
    NSTextField* nameTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
    if(nameTextField)
    {
        nameTextField.tag = ZMSDKHCITEM_TAG_NAME;
        nameTextField.autoresizingMask = NSViewMinYMargin|NSViewMaxYMargin|NSViewWidthSizable;
        nameTextField.stringValue = @"unknow";
        nameTextField.font = [NSFont systemFontOfSize:13];
        nameTextField.backgroundColor = [NSColor clearColor];
        nameTextField.textColor = [NSColor colorWithDeviceRed:52/255.0 green:52/255.0 blue:52/255.0 alpha:1.0];
        [nameTextField setBordered:NO];
        [nameTextField setEditable:NO];
        [nameTextField setSelectable:NO];
        [nameTextField sizeToFit];
        [nameTextField.cell setLineBreakMode:NSLineBreakByTruncatingTail];
        [self addSubview:nameTextField];
        nameTextField = nil;
    }
}

-(void)setUserInfo:(int)userId
{
    self.userId = userId;
}
- (void)updateUI
{
    [self updatePanelistUI];
    [self updateState];
}
- (void)updateState
{
    [self updatePanelistStateUI];
    [self layoutUI];
}
- (void)updatePanelistUI{
    ZoomSDKMeetingService* meetingService = [[ZoomSDK sharedSDK] getMeetingService];
    ZoomSDKMeetingActionController* meetingActionController = [meetingService getMeetingActionController];
    if(!meetingActionController)
        return;
    
    ZoomSDKUserInfo* userInfo = [meetingActionController getUserByUserID:_userId];
    if(!userInfo)
        return;
    
    NSString* userName = [userInfo getUserName];
    if(!userName)
        userName = @"unknow";
    //avatar icon
    ZMSDKRoundImageView* avatarImageView = [self viewWithTag:ZMSDKHCITEM_TAG_ICON_AVATAR];
    if(avatarImageView)
    {
        NSImage* avatar = [ZMSDKRoundImageView generateImageWithIcon:nil string:userName imageSize:NSMakeSize(26, 26)];

        if(avatar != avatarImageView.image){
            avatarImageView.image = avatar;
            avatarImageView.alpha = 1.0;
            [avatarImageView setNeedsDisplay:YES];
        }
    }
    
    //name text field
    NSTextField* nameField = [self viewWithTag:ZMSDKHCITEM_TAG_NAME];
    if(nameField)
    {
        NSString* displayName = userName ? userName:@"unknown user";
        nameField.stringValue = displayName;
        nameField.textColor = [NSColor colorWithSRGBRed:68/255.0 green:68/255.0 blue:68/255.0 alpha:1.0];
    }
}
- (void)updatePanelistStateUI{
    [self showViewWithTag:ZMSDKHCITEM_TAG_ICON_AVATAR];
    [self showViewWithTag:ZMSDKHCITEM_TAG_NAME];
}
- (void)hideViewWithTag:(NSInteger)tag{
    NSView* theView = [self viewWithTag:tag];
    if(theView && !theView.isHidden){
        [theView setHidden:YES];
    }
}
/**
 * show a subview with a tag
 **/
- (void)showViewWithTag:(NSInteger)tag{
    NSView* theView = [self viewWithTag:tag];
    if(theView){
        if([theView isKindOfClass:[NSImageView class]])
            [theView setHidden:[(NSImageView*)theView image]==nil];
        else
            [theView setHidden:NO];
    }
}
/**
 * private mentod
 * layout UI
 **/
- (void)layoutUI{
    float xPos = 10;
    float yPos = 0;
    float width = 0;
    float height = 0;
    float frameWidth = NSWidth(self.bounds);
    float frameHeight = NSHeight(self.bounds);
    
    xPos = 26;
    float nameXPos = xPos;
    //avatar icon
    NSView* theView = [self viewWithTag:ZMSDKHCITEM_TAG_ICON_AVATAR];
    if(theView && !theView.isHidden){
        width = NSWidth(theView.bounds);
        height = NSHeight(theView.bounds);
        yPos = ceilf((frameHeight - height)/2.0);
        [theView setFrameOrigin:NSMakePoint(xPos, yPos)];
        theView = nil;
        xPos += width;
        nameXPos = xPos + 5;
    }
    
    xPos = frameWidth - 10;
    
    //name text field
    NSTextField* nameField = [self viewWithTag:ZMSDKHCITEM_TAG_NAME];
    if(nameField && !nameField.isHidden)
    {
        width = MAX(xPos - nameXPos -2, 0);
        height = nameField.attributedStringValue.size.height;
        xPos = nameXPos;
        yPos = ceilf((frameHeight-height)/2.0) - 2;
        [nameField setFrame:NSMakeRect(xPos, yPos, width, height)];
        nameField = nil;
    }
}

@end
