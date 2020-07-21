//
//  NSDictionary+Extensions.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 20.07.20.
//

#import "NSDictionary+Extensions.h"

@implementation NSDictionary (Extensions)

- (void) setMatchingValueInDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    id value = [dictionary objectForKey:key];
    if (value) {
        [self setValue:value forKey:key];
    }
}

- (void) updateMatchingValueInDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    if ([self objectForKey:key]) {
        [self setMatchingValueInDictionary:dictionary forKey:key];
    }
}

- (void) setNonexistingValueInDictionary:(NSDictionary *)dictionary forKey:(NSString *)key
{
    if (![self objectForKey:key]) {
        [self setMatchingValueInDictionary:dictionary forKey:key];
    }
}

@end
