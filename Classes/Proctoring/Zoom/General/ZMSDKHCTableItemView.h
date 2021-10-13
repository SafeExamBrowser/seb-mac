//
//  ZMSDKHCTableItemView.h
//  ZoomSDKSample
//
//  Created by derain on 2018/12/4.
//  Copyright © 2018年 zoom.us. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZMSDKHCTableItemView : NSTableRowView
@property(assign)int userId;
- (void)setUserInfo:(int)userId;
- (void)updateUI;
- (void)updateState;

@end
