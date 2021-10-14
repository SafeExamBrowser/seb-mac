//
//  ZMInvisibleWindowMgr.h
//  ZCommonUI
//
//  Created by francis zhuo on 2018/11/23.
//  Copyright © 2018 zoom. All rights reserved.
//

#import <Foundation/Foundation.h>
extern NSNotificationName const ZMUnshareableWindowsDidChanged;
extern NSNotificationName const ZMShareableWindowsDidChanged;

@interface ZMShareWindowMonitor : NSObject
+ (id)sharedMonitor;
/**
 * only main thread can call add/reomve method
 */
- (void)addUnshareableWidnow:(NSInteger)windowID;
- (void)removeUnshareableWidnow:(NSInteger)windowID;

/** return windows number array.
 *
 * It is safe to call this method from any thread in your app
 */
- (NSArray<NSNumber*>*)unshareableWindows;
/**
* It is safe to call this method from any thread in your app
*/
- (BOOL)isUnshareableWindow:(NSInteger)windowID;

/**
 * only main thread can call add/reomve method
 */
- (void)addShareableWidnow:(NSInteger)windowID;
- (void)removeShareableWidnow:(NSInteger)windowID;

/** return windows number array.
 *
 * It is safe to call this method from any thread in your app
 */
- (NSArray<NSNumber*>*)shareableWindows;
/**
 * It is safe to call this method from any thread in your app
 */
- (BOOL)isShareableWindow:(NSInteger)windowID;
@end
