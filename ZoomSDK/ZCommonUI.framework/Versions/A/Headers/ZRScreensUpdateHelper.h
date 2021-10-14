//
//  ZRScreensUpdateHelper.h
//  zmLoader
//
//  Created by Justin Fang on 11/13/17.
//  Copyright © 2017 Justin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ZRScreensUpdateHelper : NSObject {
    NSMutableDictionary*            _updateDates;
}

@property(nonatomic, readwrite, retain)NSMutableDictionary*     updateDates;

+ (ZRScreensUpdateHelper*)sharedHelper;
- (void)updateScreens;
- (void)cleanup;
- (BOOL)didDisplayUnplugged;
- (void)updateScreensForStartZR;
- (void)updateScreens2UnmirrorMode;
- (void)updateScreens2MirrorMode;

@end
