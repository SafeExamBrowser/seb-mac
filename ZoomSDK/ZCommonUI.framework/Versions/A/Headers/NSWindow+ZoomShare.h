//
//  NSWindow+InvisibleInShare.h
//  ZCommonUI
//
//  Created by francis zhuo on 2018/11/23.
//  Copyright © 2018 zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSWindow (ZoomShare)
@property(nonatomic,assign)IBInspectable BOOL shareable;
@end
