//
//  PrefsGeneralViewController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
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
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"
#import "Constants.h"
//#import "MyGlobals.h"


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
    if (![pasteboardString isEqualToString:@""]) {
        [pasteSavedStringFromPasteboardButton setEnabled:NO];
    } else {
        [pasteSavedStringFromPasteboardButton setEnabled:YES];
    }
}


// Method invoked when switching from another tab to this one
- (void)willBeDisplayed
{
    [self loadPasswords:self];
}


// Method invoked when switching from this one to another tab
- (void)willBeHidden
{
    [self savePasswords:self];
}


- (void)windowWillClose:(NSNotification *)notification
{
    if ([[MBPreferencesController sharedController].window isVisible]) {
        [self savePasswords:self];	//save admin and quit passwords
    }
    // Unbind all programmatically set bindings
    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
    [closeButton unbind:@"enabled"];
    [closeButton unbind:@"enabled2"];
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
//- (NSString*) compareAdminPasswords {
//	if ((adminPassword != nil) | (confirmAdminPassword != nil)) { 
//        //if at least one of the fields is defined
//        if (([confirmAdminPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"]) & (![adminPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"])) {
//            //when the admin password was changed (user started to edit it), then the  
//            //placeholder string in the confirm admin password field needs to be removed
//            [self setValue:nil forKey:@"confirmAdminPassword"];
//            if (adminPassword == nil) {
//                //if admin pw was deleted completely, we have to return nil (pw's match)
//                return nil;
//            }
//        }
//       	if (![adminPassword isEqualToString:confirmAdminPassword]) {
//			//if the two passwords don't match, show it in the label
//            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
//		}
//    }
//    return nil;
//}


// Method called by the bindings object controller for comparing the quit passwords
//- (NSString*) compareQuitPasswords {
//	if ((quitPassword != nil) | (confirmQuitPassword != nil)) { 
//        //if at least one of the fields is defined
//        if (([confirmQuitPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"]) & (![quitPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"])) {
//            //when the quit password was changed (user started to edit it), then the
//            //placeholder string in the confirm quit password field needs to be removed
//            [self setValue:nil forKey:@"confirmQuitPassword"];
//            if (quitPassword == nil) {
//                //if quit pw was deleted completely, we have to return nil (pw's match)
//                return nil;
//            }
//        }
//       	if (![quitPassword isEqualToString:confirmQuitPassword]) {
//			//if the two passwords don't match, show it in the label
//            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
//		}
//    }
//    return nil;
//}


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
                [self setValue:nil forKey:@"confirmSettingsPassword"];
                [adminPasswordField setStringValue:@""];
                [confirmAdminPasswordField setStringValue:@""];
                return nil;
            }
        }
        
        // Password fields contain actual passwords, not the placeholder for a hash value
       	if (![adminPassword isEqualToString:confirmAdminPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password", nil)]);
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
        }
        
        // Password fields contain actual passwords, not the placeholder for a hash value
       	if (![quitPassword isEqualToString:confirmQuitPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password", nil)]);
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
    if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"] isEqualToString:@""]) {
        adminPasswordIsHash = false;
        [self setValue:nil forKey:@"adminPassword"];
        [self setValue:nil forKey:@"confirmAdminPassword"];
    } else {
        adminPasswordIsHash = false;
        [self setValue:@"0000000000000000" forKey:@"adminPassword"];
        adminPasswordIsHash = true;
        [self setValue:@"0000000000000000" forKey:@"confirmAdminPassword"];
    }
    
    if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"] isEqualToString:@""]) {
        adminPasswordIsHash = false;
        [self setValue:nil forKey:@"quitPassword"];
        [self setValue:nil forKey:@"confirmQuitPassword"];
    } else {
        adminPasswordIsHash = false;
        [self setValue:@"0000000000000000" forKey:@"quitPassword"];
        adminPasswordIsHash = true;
        [self setValue:@"0000000000000000" forKey:@"confirmQuitPassword"];
    }
    
//    if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"] isEqualToString:@""]) {
//        //empty passwords need to be set to NIL because of the text fields' bindings
//        [self setValue:nil forKey:@"adminPassword"];
//        [self setValue:nil forKey:@"confirmAdminPassword"];
//    } else {
//        //if there actually was a hashed password set, use a placeholder string
//        [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"adminPassword"];
//        [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"confirmAdminPassword"];
//    }
    
//    if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"] isEqualToString:@""]) {
//        [self setValue:nil forKey:@"quitPassword"];
//        [self setValue:nil forKey:@"confirmQuitPassword"];
//    } else {
//        [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"quitPassword"];
//        [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"confirmQuitPassword"];
//    }
}


// Saves admin and quit passwords to the system's user defaults database
// if the proper confirm passwords are set
- (void) savePasswords:(id)sender {
    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
    // Only if the prefs window button is enabled, then we have confirmed passwords which can be saved
    if ([closeButton isEnabled]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        
        if (adminPassword == nil) {
            //if no admin pw was entered, save a empty NSData object in preferences
            [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        } else if (![adminPassword isEqual: @"𝈭𝈖𝈒𝉇𝈁𝉈"]) {
            //if password was changed, save the new hashed password in preferences
            [preferences setSecureObject:[keychainManager generateSHAHashString:adminPassword] forKey:@"org_safeexambrowser_SEB_hashedAdminPassword"];
        }
        if (quitPassword == nil) {
            //if no quit pw was entered, save a empty NSData object in preferences
            [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
        } else if (![quitPassword isEqual: @"𝈭𝈖𝈒𝉇𝈁𝉈"]) {
            //if password was changed, save the new hashed password in preferences
            [preferences setSecureObject:[keychainManager generateSHAHashString:quitPassword] forKey:@"org_safeexambrowser_SEB_hashedQuitPassword"];
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
#ifdef DEBUG
//        NSLog(@"Pasteboard string set in UserDefaults: %@", [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"]);
//        NSLog(@"Pasteboard string in Start URL text field: %@", startURL.stringValue);
#endif
        [startURL setStringValue:pasteboardString];
#ifdef DEBUG
        NSLog(@"Pasteboard string set in Start URL text field: %@", startURL.stringValue);
        NSLog(@"Pasteboard string set in UserDefaults: %@", [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"]);
#endif
    }
}


// Action for the Restart button in preferences
// Save preferences and restart SEB with the new settings
- (IBAction) restartSEB:(id)sender {
    [self.preferencesController restartSEB:sender];
    }


// Action for the Quit button in preferences
// Save preferences and quit SEB
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
    [self savePasswords:self];	//save preferences
    //stop the preferences window to be modal, so help page can be viewed properly
    [[NSApplication sharedApplication] stopModal];
    //but put it again above other windows
    [[MBPreferencesController sharedController].window newSetLevel:NSModalPanelWindowLevel];
    // Load manual page URL into browser window
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestShowHelpNotification" object:self];
    
}


@end
