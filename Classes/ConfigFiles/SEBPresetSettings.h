//
//  SEBPresetSettings.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 07.07.20.
//

#import "SEBSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface SEBPresetSettings : NSObject <SEBExtension>

+ (NSDictionary *)defaultSettings;

+ (NSArray <NSString*>*) serverTypes;

@end

NS_ASSUME_NONNULL_END
