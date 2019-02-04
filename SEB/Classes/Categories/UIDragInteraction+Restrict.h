//
//  UIDragInteraction+Restrict.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 04.02.19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIDragInteraction (Restrict)

+ (void)setupIsEnabled;
- (BOOL)restrictIsEnabled;

@end

NS_ASSUME_NONNULL_END
