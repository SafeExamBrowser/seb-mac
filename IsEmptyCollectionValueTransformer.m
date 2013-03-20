//
//  IsEmptyCollectionValueTransformer.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.13.
//
//

#import "IsEmptyCollectionValueTransformer.h"

@implementation IsEmptyCollectionValueTransformer


+ (Class)transformedValueClass
{
    return [NSNumber class];
}


+ (BOOL)allowsReverseTransformation
{
    return NO;
}


- (id)transformedValue:(id)value
{
    
    if (value == nil) return nil;
    
    if ([value respondsToSelector: @selector(count)]) {
        return [NSNumber numberWithBool:([value count] == 0)];

    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -count.",
         [value class]];
        return nil;
    }
}


@end
