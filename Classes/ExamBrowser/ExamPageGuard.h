//
//  ExamPageGuard.h
//  Safe Exam Browser
//
//  The script that keeps copy and paste working on every page and keeps pages from noticing that the
//  student switched windows, tabs or apps (see Resources/ExamPageGuard.js).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExamPageGuard : NSObject

/// JavaScript source to inject at document start into every frame of every page
+ (NSString *)scriptSource;

@end

NS_ASSUME_NONNULL_END
