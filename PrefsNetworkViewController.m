//
//  SEBController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 12.02.13.
//  Copyright (c) 2010-2013 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Karsten Burger, Marco Lehre, 
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
//  (c) 2010-2013 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Network Pane
// Network/Internet settings like URL white/blacklists, certificates and proxy settings

#import "PrefsNetworkViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"

@implementation PrefsNetworkViewController

@synthesize groupRowTableColumn;


- (NSString *)title
{
	return NSLocalizedString(@"Network", @"Title of 'Network' preference pane");
}

- (NSString *)identifier
{
	return @"NetworkPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:NSImageNameNetwork];
}

// Before displaying pane set the download directory
- (void)willBeDisplayed
{
    
}


#pragma mark Some NSOutlineView data source methods (rest is done using bindings to a NSTreeController)

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if ([outlineView parentForItem:item]) {
        // If not nil; then the item has a parent.
        return NO;
    }
    return YES;
}

/*
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn && ![outlineView parentForItem:item] && [[tableColumn identifier] isEqualToString:@"expression"]) {
        NSCell *descriptionTableColumn = [groupRowTableColumn dataCell];
        return descriptionTableColumn;
    }
    NSInteger row = [outlineView rowForItem:item];
    return [tableColumn dataCellForRow:row];
}
*/
@end
