//
//  ZMSDKThumbnailVideoItemView.h
//  ZoomSDKSample
//
//  Created by derain on 12/12/2018.
//  Copyright © 2018 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ZoomSDK/ZoomSDK.h>

@interface ZMSDKThumbnailVideoItemView : NSView
@property (nonatomic, readwrite, strong)ZoomSDKNormalVideoElement* videoItem;
@property (nonatomic, readwrite, assign)unsigned int userID;

- (void)cleanup;
- (id)initWithFrame:(NSRect)frame userID:(unsigned int)userID;

- (void)creatVideoElementViewItem;
- (void)removeVideoElementViewItem;
- (ZoomSDKNormalVideoElement*)getVideoItem;
@end
