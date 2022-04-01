//
//  PrefsGeneralViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences General Pane
// Settings for passwords to enter Preferences and quit SEB
// Buttons to quit and restart SEB, show About panel and help

#import "PrefsGeneralViewController.h"
#import "NSWindow+SEBWindow.h"
#import "RNEncryptor.h"


@implementation PrefsGeneralViewController


- (NSString *)title
{
	return NSLocalizedString(@"General", @"Title of 'General' preference pane");
}


- (NSString *)identifier
{
	return @"GeneralPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
}


- (void) awakeFromNib
{
    self.keychainManager = [[SEBKeychainManager alloc] init];

    // Create blue underlined link for "Paste from saved clipboard"
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    [paragraphStyle setAlignment:NSRightTextAlignment];

    NSDictionary *attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
                                paragraphStyle, NSParagraphStyleAttributeName,
                                [NSFont systemFontOfSize:11], NSFontAttributeName,
                                [NSColor blueColor], NSForegroundColorAttributeName,
                                [NSNumber numberWithInt:NSUnderlineStyleSingle|NSUnderlinePatternSolid], NSUnderlineStyleAttributeName,
                                nil];
    NSMutableAttributedString * linkString = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Paste from saved clipboard",nil) attributes:attributes];
    // Change size of the "link" button bounding box size according to the localized text length
    NSSize bounds = [linkString size];
    bounds.width = (bounds.width+4 <= 363) ? bounds.width+4 : 363;
    NSPoint origin = [pasteSavedStringFromPasteboardButton frame].origin;
    origin.x = 482 - bounds.width;
    [pasteSavedStringFromPasteboardButton setFrameSize:bounds]; //483, 335
    [pasteSavedStringFromPasteboardButton setFrameOrigin:origin]; //483, 335
    [pasteSavedStringFromPasteboardButton setAttributedTitle:linkString];
    
    origin = [pasteSavedStringFromPasteboardToServerURLButton frame].origin;
    origin.x = 482 - bounds.width;
    [pasteSavedStringFromPasteboardToServerURLButton setFrameSize:bounds]; //483, 335
    [pasteSavedStringFromPasteboardToServerURLButton setFrameOrigin:origin]; //483, 335
    [pasteSavedStringFromPasteboardToServerURLButton setAttributedTitle:linkString];

    // Setup bindings to the preferences window close button
    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
    NSDictionary *bindingOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"NSIsNil",NSValueTransformerNameBindingOption,nil];
    [closeButton bind:@"enabled" 
             toObject:controller 
          withKeyPath:@"selection.compareAdminPasswords" 
              options:bindingOptions];
    [closeButton bind:@"enabled2" 
             toObject:controller 
          withKeyPath:@"selection.compareQuitPasswords" 
              options:bindingOptions];
    
    myGlobals = [MyGlobals sharedMyGlobals];
//    [pasteSavedStringFromPasteboardButton bind:@"enabled"
//                                      toObject:myGlobals
//                                   withKeyPath:@"pasteboardString.length"
//                                       options:[NSDictionary dictionaryWithObject:@"BoolValueTransformer" forKey:NSValueTransformerNameBindingOption]];
    NSString *pasteboardString = [[MyGlobals sharedMyGlobals] valueForKey:@"pasteboardString"];
    if (pasteboardString.length == 0) {
        [pasteSavedStringFromPasteboardButton setEnabled:NO];
        [pasteSavedStringFromPasteboardToServerURLButton setEnabled:NO];
    } else {
        [pasteSavedStringFromPasteboardButton setEnabled:YES];
        [pasteSavedStringFromPasteboardToServerURLButton setEnabled:YES];
    }
}


// Method invoked when switching from another tab to this one
- (void)willBeDisplayed
{
    [self loadPasswords:self];
    _wasLoaded = YES;
}


// Method invoked when switching from this one to another tab
- (void)willBeHidden
{
    if (_wasLoaded) {
        [self savePasswords:self];
        _wasLoaded = NO;
    }
}


- (void)windowWillClose:(NSNotification *)notification
{
    if ([[MBPreferencesController sharedController].window isVisible]) {
        if (_wasLoaded) {
            [self savePasswords:self];	//save admin and quit passwords
            _wasLoaded = NO;
        }
    }
    // Unbind all programmatically set bindings
//    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
//    [closeButton unbind:@"enabled"];
//    [closeButton unbind:@"enabled2"];
    //    [pasteSavedStringFromPasteboardButton unbind:@"enabled"];
}


// Definitition of the dependent keys for comparing admin passwords
+ (NSSet *)keyPathsForValuesAffectingCompareAdminPasswords {
    return [NSSet setWithObjects:@"adminPassword", @"confirmAdminPassword", nil];
}


// Definitition of the dependent keys for comparing quit passwords
+ (NSSet *)keyPathsForValuesAffectingCompareQuitPasswords {
    return [NSSet setWithObjects:@"quitPassword", @"confirmQuitPassword", nil];
}


// Method called by the bindings object controller for comparing the admin passwords
- (NSString*) compareAdminPasswords
{
	if ((adminPassword != nil) | (confirmAdminPassword != nil)) {
        
        // If the flag is set for password fields contain a placeholder
        // instead of the hash loaded from settings (no cleartext password)
        if (adminPasswordIsHash)
        {
            if (![adminPassword isEqualToString:confirmAdminPassword])
            {
                // and when the password texts aren't the same anymore, this means the user tries to edit the password
                // (which is only the placeholder right now), we have to clear the placeholder from the textFields
                adminPasswordIsHash = false;
                [self setValue:nil forKey:@"adminPassword"];
                [self setValue:nil forKey:@"confirmAdminPassword"];
                [adminPasswordField setStringValue:@""];
                [confirmAdminPasswordField setStringValue:@""];
                return nil;
            }
        } else {
            // Password fields contain actual passwords, not the placeholder for a hash value
            if (![adminPassword isEqualToString:confirmAdminPassword]) {
                //if the two passwords don't match, show it in the label
                return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please enter correct confirm password", nil)]);
            }
        }
    }
    return nil;
}


// Method called by the bindings object controller for comparing the quit passwords
- (NSString*) compareQuitPasswords
{
	if ((quitPassword != nil) | (confirmQuitPassword != nil)) {
        
        // If the flag is set for password fields contain a placeholder
        // instead of the hash loaded from settings (no cleartext password)
        if (quitPasswordIsHash)
        {
            if (![quitPassword isEqualToString:confirmQuitPassword])
            {
                // and when the password texts aren't the same anymore, this means the user tries to edit the password
                // (which is only the placeholder right now), we have to clear the placeholder from the textFields
                quitPasswordIsHash = false;
                [self setValue:nil forKey:@"quitPassword"];
                [self setValue:nil forKey:@"confirmQuitPassword"];
                [quitPasswordField setStringValue:@""];
                [confirmQuitPasswordField setStringValue:@""];
                return nil;
            }
        } else {
            // Password fields contain actual passwords, not the placeholder for a hash value
            if (![quitPassword isEqualToString:confirmQuitPassword]) {
                //if the two passwords don't match, show it in the label
                return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please enter correct confirm password", nil)]);
            }
        }
    }
    return nil;
}


/*
- (BOOL) isPasteboardString {
    if ([[[MyGlobals sharedMyGlobals] pasteboardString] isEqualToString:@""]) 
        return NO;
    else return YES; 
}
*/


// Loads admin and quit passwords from the system's user defaults database
- (void) loadPasswords:(id)sender {
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    // CAUTION: We need to reset this flag BEFORE changing the textBox text value,
    // because otherwise the compare passwords method will delete the first textBox again.
    if ([[preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"] isEqualToString:@""]) {
        adminPasswordIsHash = NO;
        [self setValue:nil forKey:@"adminPassword"];
        [self setValue:nil forKey:@"confirmAdminPassword"];
    } else {
        adminPasswordIsHash = NO;
        [self setValue:@"0000000000000000" forKey:@"adminPassword"];
        adminPasswordIsHash = YES;
        [self setValue:@"0000000000000000" forKey:@"confirmAdminPassword"];
    }
    
    if ([[preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"] isEqualToString:@""]) {
        quitPasswordIsHash = NO;
        [self setValue:nil forKey:@"quitPassword"];
        [self setValue:nil forKey:@"confirmQuitPassword"];
    } else {
        quitPasswordIsHash = NO;
        [self setValue:@"0000000000000000" forKey:@"quitPassword"];
        quitPasswordIsHash = YES;
        [self setValue:@"0000000000000000" forKey:@"confirmQuitPassword"];
    }
}


// Saves admin and quit passwords to the system's user defaults database
// if the proper confirm passwords are set
- (void) savePasswords:(id)sender {
    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
    // Only if the prefs window button is enabled, then we have confirmed passwords which can be saved
    if ([closeButton isEnabled]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        if (adminPassword.length == 0) {
            //if no admin pw was entered, save a empty string in preferences
            [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        } else if (adminPasswordIsHash == false) {
            //if password was changed, save the new hashed password in preferences
            [preferences setSecureObject:[self.keychainManager generateSHAHashString:adminPassword] forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        }
        if (quitPassword.length == 0) {
            //if no quit pw was entered, save a empty string in preferences
            [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        } else if (quitPasswordIsHash == false) {
            //if password was changed, save the new hashed password in preferences
            [preferences setSecureObject:[self.keychainManager generateSHAHashString:quitPassword] forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        }
    }
}


#pragma mark -
#pragma mark IBActions: Button actions for displaying About SEB and help,
#pragma mark pasting saved string from pasteboard, quitting and restarting SEB.

- (IBAction) pasteSavedStringFromPasteboard:(id)sender {
    NSString *pasteboardString = [[MyGlobals sharedMyGlobals] valueForKey:@"pasteboardString"];
    if (![pasteboardString isEqualToString:@""]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureString:pasteboardString forKey:@"org_safeexambrowser_SEB_startURL"];
        [startURL setStringValue:pasteboardString];
    }
}


- (IBAction) pasteSavedStringFromPasteboardToServerURL:(id)sender {
    NSString *pasteboardString = [[MyGlobals sharedMyGlobals] valueForKey:@"pasteboardString"];
    if (![pasteboardString isEqualToString:@""]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureString:pasteboardString forKey:@"org_safeexambrowser_SEB_sebServerURL"];
        [sebServerURL setStringValue:pasteboardString];
    }
}


// Action for the Restart button in preferences
// Save preferences and restart SEB with the new settings
- (IBAction) restartSEB:(id)sender {
    [self.preferencesController restartSEB:sender];
    }


// Action for the Quit button in preferences
// Save preferences and exit SEB
- (IBAction) quitSEB:(id)sender {
    [self.preferencesController quitSEB:sender];
}


// Action for the About button in preferences
- (IBAction) aboutSEB:(id)sender {
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestShowAboutNotification" object:self];
}


// Action for the Help button in preferences
- (IBAction) showHelp:(id)sender {
    // Open manual page URL in a new browser window
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestShowHelpNotification" object:self];
}


@end
