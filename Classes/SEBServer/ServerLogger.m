//
//  ServerLogger.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 09.09.19.
//

#import "ServerLogger.h"

@implementation ServerLogger


+ (ServerLogger *) sharedInstance
{
    static dispatch_once_t pred = 0;
    static ServerLogger *_sharedInstance = nil;
    
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}


- (void)logMessage:(DDLogMessage *)logMessage {
    NSString *logMessageString = logMessage.message;
    
    if (logMessageString) {
        [_sebViewController sendLogEventWithLogLevel:logMessage.level
                                           timestamp:[NSString stringWithFormat:@"%.0f", logMessage.timestamp.timeIntervalSince1970 * 1000]
                                        numericValue:(double)logMessage.context
                                             message:logMessageString];
    }
}


@end
