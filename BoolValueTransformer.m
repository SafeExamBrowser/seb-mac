//
//  BoolValueTransformer.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.13.
//
//

#import "BoolValueTransformer.h"

@implementation BoolValueTransformer


+ (Class)transformedValueClass
{
    //return [NSNumber class];
    return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
    return YES;
}


/*- (id)transformedValue:(id)value
{
    BOOL boolValue;
    
    if (value == nil) return nil;
    
    // Attempt to get a reasonable value from the
    // value object.
    if ([value isKindOfClass:[NSNumber class]]) {
        
        boolValue = [value boolValue];
        
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) is not member of class NSNumber.",
         [value class]];
    }
    return [NSNumber numberWithBool:boolValue];
}


- (id)reverseTransformedValue:(id)value
{
    NSString *stringValue;
    
    if (value == nil) return nil;
    
    if ([value respondsToSelector: @selector(boolValue)]) {
        stringValue = [value stringValue];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -boolValue.",
         [value class]];
    }
    
    return stringValue;
}
*/


 - (id)transformedValue:(id)value
 {
 NSString *stringValue;
 
 if (value == nil) return nil;
 
 if ([value respondsToSelector: @selector(boolValue)]) {
 stringValue = [value stringValue];
 } else {
 [NSException raise: NSInternalInconsistencyException
 format: @"Value (%@) does not respond to -boolValue.",
 [value class]];
 }
 
 return stringValue;
 }
 
 
 - (id)reverseTransformedValue:(id)value
 {
 BOOL boolValue;
 
 if (value == nil) return nil;
 
 // Attempt to get a reasonable value from the
 // value object.
 if ([value isKindOfClass:[NSNumber class]]) {
 
 boolValue = [value boolValue];
 
 } else {
 [NSException raise: NSInternalInconsistencyException
 format: @"Value (%@) is not member of class NSNumber.",
 [value class]];
 }
 return [NSNumber numberWithBool:boolValue];
 }
 
 
@end
