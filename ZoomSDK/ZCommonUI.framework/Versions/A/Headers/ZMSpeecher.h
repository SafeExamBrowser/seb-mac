//
//  ZMSpeecher.h
//  ZCommonUI
//
//  Created by Yang on 2016/9/19.
//  Copyright © 2016年 zoom. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ZMSpeecher : NSObject
{
    NSSpeechSynthesizer * _synthesizer;
    NSMutableArray * _prepareStrings;
}

+ (void)speakString:(NSString *)string;
+ (void)speakStringWithSynthesizer:(NSString *)string;
+ (BOOL)speakString:(NSString *)string toUrl:(NSURL *)url;//[zoom-35476]

@end
