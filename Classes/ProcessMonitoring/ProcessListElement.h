//
//  ProcessList.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 31.07.20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProcessListElement : NSObject

@property (strong, nonatomic) NSImage *icon;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSString *bundleID;
@property (readwrite, nonatomic) BOOL terminated;

- (instancetype)initWithProcess:(id)process;

@end

NS_ASSUME_NONNULL_END
