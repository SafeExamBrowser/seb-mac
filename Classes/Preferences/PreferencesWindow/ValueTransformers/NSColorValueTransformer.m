//
//  BoolValueTransformer.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.13.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "NSColorValueTransformer.h"

@implementation NSColorValueTransformer


+ (Class)transformedValueClass
{
    return [NSColor class];
}


+ (BOOL)allowsReverseTransformation
{
    return NO;
}


- (id)transformedValue:(id)value
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
    return boolValue ? [NSColor redColor] : [NSColor blackColor];
}

 
@end
