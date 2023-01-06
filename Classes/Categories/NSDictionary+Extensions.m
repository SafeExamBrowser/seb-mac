//
//  NSDictionary+Extensions.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 20.07.20.
//

#import "NSDictionary+Extensions.h"
#import "NSArray+Extensions.h"


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

- (BOOL) containsDictionary:(NSDictionary *)dictionary
{
    NSArray *allKeys = dictionary.allKeys;
    for (id key in allKeys) {
        id value = [dictionary objectForKey:key];
        Class valueClass = [value superclass];
        id object = [self objectForKey:key];
        Class objectClass = [object superclass];
        
        if (value && object && (valueClass == NSDictionary.class || valueClass == NSMutableDictionary.class)) {
            if (objectClass == NSDictionary.class || objectClass == NSMutableDictionary.class) {
                if (![object containsDictionary:value]) {
                    return NO;
                }
            } else {
                return NO;
            }
        } else if (value && object && (valueClass == NSArray.class || valueClass == NSMutableArray.class)) {
            if (objectClass == NSArray.class || objectClass == NSMutableArray.class) {
                if (![object containsArray:value]) {
                    return NO;
                }
            } else {
                return NO;
            }
        } else if (![value isEqual:object]) {
            return NO;
        }
    }
    return YES;
}

@end
