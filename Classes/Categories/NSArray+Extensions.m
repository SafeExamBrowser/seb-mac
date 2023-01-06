//
//  NSArray+Extensions.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 03.01.23.
//

#import "NSArray+Extensions.h"
#import "NSDictionary+Extensions.h"

@implementation NSArray (Extensions)

- (BOOL) containsArray:(NSArray *)array
{
    for (id object in array) {
        Class objectClass = [object superclass];
        
        if (object && (objectClass == NSDictionary.class || objectClass == NSMutableDictionary.class)) {
            BOOL dictionaryExists = NO;
            for (NSDictionary *dictionary in self) {
                if ([dictionary containsDictionary:object]) {
                    dictionaryExists = YES;
                    break;
                } else if ([object containsDictionary:dictionary]) {
                    dictionaryExists = YES;
                    break;
                }
            }
            if (!dictionaryExists) {
                return NO;
            }

        } else if (![self containsObject:object]) {
            return NO;
        }
    }
    return YES;
}

@end
