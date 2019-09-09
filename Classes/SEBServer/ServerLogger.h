//
//  ServerLogger.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 09.09.19.
//

#import <Foundation/Foundation.h>
#import "DDLog.h"
#import "SEBViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ServerLogger : DDAbstractLogger <DDLogger>

@property (weak) SEBViewController *sebViewController;

+ (ServerLogger *) sharedInstance;

@end

NS_ASSUME_NONNULL_END
