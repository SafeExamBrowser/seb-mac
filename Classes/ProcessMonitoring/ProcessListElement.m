//
//  ProcessList.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 31.07.20.
//

#import "ProcessListElement.h"

@interface ProcessListElement() {
    @private
    NSRunningApplication *runningApplication;
    NSDictionary *runningProcess;
}
@end

@implementation ProcessListElement

- (instancetype)initWithProcess:(id)process
{
    self = [super init];
    if (self) {
        if ([process isKindOfClass:[NSRunningApplication class]]) {
            runningApplication = (NSRunningApplication *)process;
            if (runningApplication.terminated) {
                return nil;
            }
        } else if ([process isKindOfClass:[NSDictionary class]]) {
            runningProcess = (NSDictionary *)process;
        }
    }
    return self;
}

- (NSImage *)icon
{
    if (runningApplication) {
        return runningApplication.icon;
    } else {
        return nil;
    }
}

- (NSString *)name
{
    if (runningApplication) {
        return runningApplication.localizedName;
    } else {
        return runningProcess[@"name"];
    }
}

- (NSString *)bundleID
{
    if (runningApplication) {
        return runningApplication.bundleIdentifier;
    } else {
        return nil;
    }
}

- (BOOL)terminated
{
    if (runningApplication) {
        return runningApplication.terminated;
    } else {
        return YES;
    }
}

@end
