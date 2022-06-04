//
//  Constants.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 31.10.14.
//
//

#import "Constants.h"

@implementation Constants : NSObject 

- (NSArray *)ddLogLevels {
    return [NSArray arrayWithObjects:[NSNumber numberWithInt:SEBLogLevelError], [NSNumber numberWithInt:SEBLogLevelWarning], [NSNumber numberWithInt:SEBLogLevelInfo], [NSNumber numberWithInt:SEBLogLevelDebug], [NSNumber numberWithInt:SEBLogLevelVerbose], nil];

}

@end
