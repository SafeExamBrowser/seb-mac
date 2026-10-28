//
//  ExamPageGuard.m
//  Safe Exam Browser
//

#import "ExamPageGuard.h"

@implementation ExamPageGuard

+ (NSString *)scriptSource
{
    static NSString *source;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *scriptURL = [[NSBundle mainBundle] URLForResource:@"ExamPageGuard" withExtension:@"js"];
        source = scriptURL ? [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:nil] : nil;
        if (source.length == 0) {
            source = @"";
        }
    });
    return source;
}

@end
