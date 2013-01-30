//
//  SEBController.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 18.04.11.
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

- (void) awakeFromNib
{
    [[MBPreferencesController sharedController].window setDelegate:self];
#ifdef DEBUG
    NSLog(@"Set PrefsGeneralViewController as delegate for preferences window");
#endif
    
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
    [pasteSavedStringFromPasteboardButton bind:@"enabled"
                                      toObject:myGlobals
                                   withKeyPath:@"pasteboardString.length"
                                       options:nil];
}


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


- (void)willBeDisplayed
{
    [self loadPrefs:self];
}


- (void)willBeHidden
{
    NSButton *closeButton = [[MBPreferencesController sharedController].window standardWindowButton:NSWindowCloseButton];
    // Only is the prefs window button is enabled, then we have confirmed passwords which can be saved
    if ([closeButton isEnabled]) {
        [self savePrefs:self];	//save preferences when pane is switched
    }
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
- (NSString*) compareAdminPasswords {
	if ((adminPassword != nil) | (confirmAdminPassword != nil)) { 
        //if at least one of the fields is defined
        if (([confirmAdminPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"]) & (![adminPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"])) {
            //when the admin password was changed (user started to edit it), then the  
            //placeholder string in the confirm admin password field needs to be removed
            [self setValue:nil forKey:@"confirmAdminPassword"];
            if (adminPassword == nil) {
                //if admin pw was deleted completely, we have to return nil (pw's match)
                return nil;
            }
        }
       	if (![adminPassword isEqualToString:confirmAdminPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
		}
    }
    return nil;
}


// Method called by the bindings object controller for comparing the quit passwords
- (NSString*) compareQuitPasswords {
	if ((quitPassword != nil) | (confirmQuitPassword != nil)) { 
        //if at least one of the fields is defined
        if (([confirmQuitPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"]) & (![quitPassword isEqual:@"𝈭𝈖𝈒𝉇𝈁𝉈"])) {
            //when the quit password was changed (user started to edit it), then the  
            //placeholder string in the confirm quit password field needs to be removed
            [self setValue:nil forKey:@"confirmQuitPassword"];
            if (quitPassword == nil) {
                //if admin pw was deleted completely, we have to return nil (pw's match)
                return nil;
            }
        }
       	if (![quitPassword isEqualToString:confirmQuitPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
		}
    }
    return nil;
}

/*
// Method called by the bindings object controller for comparing the quit passwords
- (BOOL) isPasteboardString {
    if ([[[MyGlobals sharedMyGlobals] pasteboardString] isEqualToString:@""]) 
        return NO;
    else return YES; 
}
*/

- (void) loadPrefs:(id)sender {
	// Loads preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    //NSString *url = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    NSString *url = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
    if (url) { //if there is no preferences file yet, startURL can be nil during first execution of this method
       	[startURL setStringValue:url];
        
        if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"] isEqualToString:@""]) {
            //empty passwords need to be set to NIL because of the text fields' bindings 
            //([NSData data] produces an empty NSData object)
            [self setValue:nil forKey:@"adminPassword"];
            [self setValue:nil forKey:@"confirmAdminPassword"];
        } else {
            //if there actually was a hashed password set, use a placeholder string
            [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"adminPassword"];
            [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"confirmAdminPassword"];
        }
        
        if ([[preferences secureObjectForKey:@"org_safeexambrowser_SEB_hashedQuitPassword"] isEqualToString:@""]) {
            [self setValue:nil forKey:@"quitPassword"];
            [self setValue:nil forKey:@"confirmQuitPassword"];
        } else {
            [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"quitPassword"];
            [self setValue:@"𝈭𝈖𝈒𝉇𝈁𝉈" forKey:@"confirmQuitPassword"];
        }
    }
}


- (void) savePrefs:(id)sender {
	// Saves preferences to the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    /*/ Load start URL from the system's user defaults database
    if (![[preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"] isEqualToString:startURL.stringValue]) {
        [preferences setSecureObject:[startURL stringValue] forKey:@"org_safeexambrowser_SEB_startURL"];
        // Post a notification that it was requested to reload start URL
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestRestartNotification" object:self];
    }*/

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


// Action saving current preferences to a plist-file in application bundle Contents/Resources/ directory
- (IBAction) savePrefsToAppBundle:(id)sender {
    [self savePrefs:self];	//save preferences (which are not saved automatically by bindings)
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences synchronize];
    NSDictionary *prefsDict;
    // Get CFBundleIdentifier of the application
    NSDictionary *bundleInfo = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleId = [bundleInfo objectForKey: @"CFBundleIdentifier"];
    // Include UserDefaults from NSRegistrationDomain and the applications domain
    NSUserDefaults *appUserDefaults = [[NSUserDefaults alloc] init];
    [appUserDefaults addSuiteNamed:@"NSRegistrationDomain"];
    [appUserDefaults addSuiteNamed: bundleId];
    prefsDict = [appUserDefaults dictionaryRepresentation];
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [prefsDict keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                               {
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"])
                                       return YES;
                                   else
                                       return NO;
                               }];
    NSArray *allSEBKeys = [filteredPrefsSet allObjects];
    NSArray *allSEBValues = [prefsDict objectsForKeys:allSEBKeys notFoundMarker:[NSData data]];
    NSDictionary *filteredPrefsDict = [NSDictionary dictionaryWithObjects:allSEBValues forKeys:allSEBKeys];
    // Save initialValues to a SEB preferences file into the application bundle
    NSString *prefsPath;
    prefsPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/org.safeexambrowser.Safe-Exam-Browser.plist"];
    if (![filteredPrefsDict writeToFile:prefsPath atomically:YES]) {
        // If the prefs file couldn't be written to app bundle
        NSRunAlertPanel(NSLocalizedString(@"Writing Settings to App Bundle Failed", nil),
                        NSLocalizedString(@"Probably you don't have write permissions. Try to move or copy the app to a directory you have permission to write in (like the Desktop) or change the file permissions manually in Finder.", nil),
                        NSLocalizedString(@"OK", nil), nil, nil);
    } else {
        // Prefs got successfully written to app bundle
        // Set flag for preferences in app bundle (bindings enable the remove button in prefs same time)
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureObject:[NSNumber numberWithBool:YES] forKey:@"org_safeexambrowser_SEB_prefsInBundle"];
        NSRunAlertPanel(NSLocalizedString(@"Writing Settings to App Bundle Succeeded", nil), NSLocalizedString(@"WritingToAppBundleSucceeded", nil), NSLocalizedString(@"OK", nil), nil, nil);
    }
}


// Action removing the preferences plist-file in application bundle Contents/Resources/ directory
- (IBAction) removePrefsFromAppBundle:(id)sender {
    NSError *error = nil;
    NSString *fullPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/org.safeexambrowser.Safe-Exam-Browser.plist"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
        BOOL itemRemoved = [[NSFileManager defaultManager] removeItemAtPath:fullPath error:&error];
        if (itemRemoved == NO) {
            // If the prefs file couldn't be deleted from the app bundle
            NSString *errorText = [NSLocalizedString(@"RemovingFromAppBundleFailed", nil) stringByAppendingString:[error localizedDescription]];
            
            NSRunAlertPanel(NSLocalizedString(@"Removing Settings from the App Bundle Failed", nil), errorText, NSLocalizedString(@"OK", nil), nil, nil);               
        } else {
            // Prefs got successfully deleted from app bundle
            // Reset flag for preferences in app bundle (bindings disable the remove button in prefs same time)
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            [preferences setSecureObject:[NSNumber numberWithBool:NO] forKey:@"org_safeexambrowser_SEB_prefsInBundle"];
        }
    }
}


- (IBAction) pasteSavedStringFromPasteboard:(id)sender {
    NSString *pasteboardString = [[MyGlobals sharedMyGlobals] pasteboardString];
    if (![pasteboardString isEqualToString:@""]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        [preferences setSecureObject:pasteboardString forKey:@"org_safeexambrowser_SEB_startURL"];
    }
}


// Action for the Restart button in preferences
// Save preferences and restart SEB with the new settings
- (IBAction) restartSEB:(id)sender {
    [self savePrefs:self];	//save preferences
    // Close preferences window
	[self closePreferencesWindow:self];

    // Post a notification that it was requested to reload start URL
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestRestartNotification" object:self];
    }


// Action for the Quit button in preferences
// Save preferences and quit SEB
- (IBAction) quitSEB:(id)sender {
    [self savePrefs:self];	//save preferences
    // Close preferences window
	[self closePreferencesWindow:self];
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestQuitNotification" object:self];
}


- (void) closePreferencesWindow:(id)sender {
    [[MBPreferencesController sharedController].window orderOut:self];
    [[NSApplication sharedApplication] stopModal];
    // Post a notification that preferences were closed
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"preferencesClosed" object:self];
}


// Action for the About button in preferences
- (IBAction) aboutSEB:(id)sender {
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestShowAboutNotification" object:self];
}


// Action for the Help button in preferences
- (IBAction) showHelp:(id)sender {
    [self savePrefs:self];	//save preferences
    //stop the preferences window to be modal, so help page can be viewed properly
    [[NSApplication sharedApplication] stopModal];
    //but put it again above other windows
    [[MBPreferencesController sharedController].window newSetLevel:NSModalPanelWindowLevel];
    // Load manual page URL into browser window
	[[NSNotificationCenter defaultCenter]
     postNotificationName:@"requestShowHelpNotification" object:self];
    
}


- (NSData*) generateSHAHash:(NSString*)inputString {
    unsigned char hashedChars[32];
    CC_SHA256([inputString UTF8String],
              [inputString lengthOfBytesUsingEncoding:NSUTF8StringEncoding], 
              hashedChars);
    NSData *hashedData = [NSData dataWithBytes:hashedChars length:32];
    return hashedData;
}


- (void)windowDidBecomeKey:(NSNotification *)notification
{
    [self loadPrefs:self];
}


- (void)windowWillClose:(NSNotification *)notification
{
    if ([[MBPreferencesController sharedController].window isVisible]) {
        [self savePrefs:self];	//save preferences
        [[NSApplication sharedApplication] stopModal];
#ifdef DEBUG
        NSLog(@"windowWillClose: stopModal");
#endif
        // Post a notification that preferences were closed
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"preferencesClosed" object:self];
    }
}

@end
