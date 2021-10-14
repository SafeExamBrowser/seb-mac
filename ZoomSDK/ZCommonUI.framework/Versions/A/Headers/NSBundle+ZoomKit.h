//
//  NSBundle+ZoomKit.h
//  ZCommonUI
//
//  Created by Francis Zhuo on 4/15/21.
//  Copyright © 2021 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBundle (ZoomKit)
+ (BOOL)loadBundleWithComponentName:(NSString*)componentName;
@end

NS_ASSUME_NONNULL_END
