//
//  SEBWindowSizeValueTransformer.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.02.13.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBWindowSizeValueTransformer.h"

@implementation SEBWindowSizeValueTransformer


+ (Class)transformedValueClass
{
    return [NSString class];
}


+ (BOOL)allowsReverseTransformation
{
    return YES;
}


- (id)transformedValue:(id)value
{
    NSString *windowSize;
    
    if (value == nil) return nil;
    
    if ([value respondsToSelector: @selector(integerValue)]) {
        if ([value intValue] == 0)
            windowSize = @"Screen";
        else
            windowSize = [value stringValue];
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) does not respond to -integerValue.",
         [value class]];
    }
    
    return windowSize;
}


- (id)reverseTransformedValue:(id)value
{
    NSInteger windowSize;
    
    if (value == nil) return nil;
    
    // Attempt to get a reasonable value from the
    // value object.
    if ([value isKindOfClass:[NSString class]]) {
        
        if ([value isEqualToString:@"Screen"])
            windowSize = 0;
        else
            windowSize = [value integerValue];
        
    } else {
        [NSException raise: NSInternalInconsistencyException
                    format: @"Value (%@) is not member of class NSString.",
         [value class]];
    }
    return [NSNumber numberWithInteger:windowSize];
}

@end
