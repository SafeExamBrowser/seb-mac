//
//  MyNSBezierPath.h
//  SafeExamBrowser
//
//  Created by Gerhard Muendane on 09.03.22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSBezierPath (BezierPathQuartzUtilities)
    // This method works only in OS X v10.2 and later.
- (CGPathRef)quartzPath;

@end

NS_ASSUME_NONNULL_END
