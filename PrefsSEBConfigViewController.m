//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import "PrefsSEBConfigViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "SEBConfigFileManager.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"
#import "MyGlobals.h"
#import "Constants.h"

@interface PrefsSEBConfigViewController ()

@end

@implementation PrefsSEBConfigViewController
@synthesize identitiesNames;
@synthesize identities;


- (NSString *)title
{
	return NSLocalizedString(@"Config File", @"Title of 'SEB Config' preference pane");
}


- (NSString *)identifier
{
	return @"SEBConfigPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"sebConfigIcon"];
}


// Definitition of the dependent keys for comparing settings passwords
+ (NSSet *)keyPathsForValuesAffectingCompareSettingsPasswords {
    return [NSSet setWithObjects:@"settingsPassword", @"confirmSettingsPassword", nil];
}


// Method called by the bindings object controller for comparing the settings passwords
- (NSString*) compareSettingsPasswords {
	if ((settingsPassword != nil) | (confirmSettingsPassword != nil)) {
       	if (![settingsPassword isEqualToString:confirmSettingsPassword]) {
			//if the two passwords don't match, show it in the label
            return (NSString*)([NSString stringWithString:NSLocalizedString(@"Please confirm password",nil)]);
		} else {
            //[self savePrefs];
        }
    }
    return nil;
}


// Delegate called before the Exam settings preferences pane will be displayed
- (void)willBeDisplayed {
    //Load settings password from user defaults
    //[self loadPrefs];
    //[chooseIdentity synchronizeTitleAndSelectedItem];
    if (!self.identitiesNames) { //no identities available yet, get them from keychain
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        NSArray *names;
        NSArray *identitiesInKeychain = [keychainManager getIdentitiesAndNames:&names];
        self.identities = identitiesInKeychain;
        self.identitiesNames = [names copy];
        [chooseIdentity removeAllItems];
        //first put "None" item in popupbutton list
        [chooseIdentity addItemWithTitle:NSLocalizedString(@"None", nil)];
        [chooseIdentity addItemsWithTitles: self.identitiesNames];
    }
}


- (void) loadPrefs {
	// Loads preferences from the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *settingsPwd = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_settingsPassword"];
    if ([settingsPwd isEqualToString:@""]) {
        //empty passwords need to be set to NIL because of the text fields' bindings
        [self setValue:nil forKey:@"settingsPassword"];
        [self setValue:nil forKey:@"confirmSettingsPassword"];
    } else {
        //if there actually was a hashed password set, use a placeholder string
        [self setValue:settingsPwd forKey:@"settingsPassword"];
        [self setValue:settingsPwd forKey:@"confirmSettingsPassword"];
    }
}


- (void) savePrefs {
	// Saves preferences to the system's user defaults database
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    if (settingsPassword == nil) {
        //if no settings pw was entered, save a empty NSData object in preferences
        [preferences setSecureObject:@"" forKey:@"org_safeexambrowser_SEB_settingsPassword"];
    } else
        //if password was changed, save the new password in preferences
        [preferences setSecureObject:settingsPassword forKey:@"org_safeexambrowser_SEB_settingsPassword"];
}


// Action formating and saving current preferences to an encrypted .seb file
//
- (IBAction) saveSEBPrefs:(id)sender {
    SEBConfigFileManager *configFileManager = [[SEBConfigFileManager alloc] init];
    
    // Get SecIdentityRef for selected identity
    SecIdentityRef identityRef = nil;
    if ([chooseIdentity indexOfSelectedItem]) {
        // If an identity is selected, then we get the according SecIdentityRef
        NSInteger selectedIdentity = [chooseIdentity indexOfSelectedItem]-1;
        identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity]);
    }

    // Get selected config purpose
    sebConfigPurposes configPurpose = [sebPurpose selectedRow];
    
    // Read SEB settings from UserDefaults and encrypt them using the provided security credentials
    NSData *encryptedSebData = [configFileManager encryptSEBSettingsWithPassword:settingsPassword withIdentity:identityRef forPurpose:configPurpose];
    
    // If SEB settings were actually read and encrypted we save them
    if (encryptedSebData) {
        // Set the default name for the file and show the panel.
        NSSavePanel *panel = [NSSavePanel savePanel];
        //[panel setNameFieldStringValue:newName];
        [panel setAllowedFileTypes:[NSArray arrayWithObject:@"seb"]];
        [panel beginSheetModalForWindow:[MBPreferencesController sharedController].window
                      completionHandler:^(NSInteger result){
                          if (result == NSFileHandlingPanelOKButton)
                          {
                              NSURL*  prefsFileURL = [panel URL];
                              // Write the contents in the new format.
                              if (![encryptedSebData writeToURL:prefsFileURL atomically:YES]) {
                                  //if (![filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                                  // If the prefs file couldn't be written to app bundle
                                  NSRunAlertPanel(NSLocalizedString(@"Writing Settings Failed", nil),
                                                  NSLocalizedString(@"Make sure you have write permissions in the chosen directory", nil),
                                                  NSLocalizedString(@"OK", nil), nil, nil);
                              } else {
                                  // Prefs got successfully written to file
                                  NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), ([sebPurpose selectedRow]) ? NSLocalizedString(@"Encrypted settings have been saved, use this file to reconfigure local settings of a SEB client.", nil) : NSLocalizedString(@"Encrypted settings have been saved, use this file to start the exam with SEB.", nil), NSLocalizedString(@"OK", nil), nil, nil);
#ifdef DEBUG
                                  /*prefsFileURL = [[prefsFileURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"plist"];
                                   if ([filteredPrefsDict writeToURL:prefsFileURL atomically:YES]) {
                                   NSLog(@"Unencrypted preferences saved as plist");
                                   }*/
#endif
                              }
                          }
                      }];
    }
}


@end
