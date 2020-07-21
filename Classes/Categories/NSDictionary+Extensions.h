//
//  NSDictionary+Extensions.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 20.07.20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (Extensions)

- (void) setMatchingValueInDictionary: (NSDictionary *)dictionary forKey:(NSString *)key;
- (void) updateMatchingValueInDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;
- (void) setNonexistingValueInDictionary:(NSDictionary *)dictionary forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
