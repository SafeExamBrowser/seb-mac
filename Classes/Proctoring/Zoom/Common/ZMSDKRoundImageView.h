//
//  ZMSDKRoundImageView.h
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZMSDKRoundImageView : NSControl
{
@private
    NSImage*                                _image;
    int                                     _messageNumber;
    BOOL                                    _isRound;
    int                                     _radius;
    BOOL                                    _notCompressSize;
    float                                   _alpha;
}

@property (nonatomic, readwrite, strong) NSImage* image;
@property (nonatomic, readwrite, assign) int messageNumber;
@property (nonatomic, readwrite, assign) BOOL isRound;
@property (nonatomic, readwrite, assign) int radius;
@property (assign) BOOL notCompressSize;
@property (assign) float alpha;

- (void)cleanup;
- (void)generateBackColorWithUserID:(NSString*)userID;
- (void)generateImageWithName:(NSString*)name userID:(NSString*)userID;
+ (NSImage*)generateFixedSizeImageWithName:(NSString*)name userID:(NSString*)userID;
+ (NSImage*)generateImageWithIcon:(NSImage*)inIcon string:(NSString*)inString imageSize:(NSSize)inSize;
+ (NSColor*)getColorWithUserID:(NSString*)userID;
@end


