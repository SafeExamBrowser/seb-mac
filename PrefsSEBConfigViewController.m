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
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *filteredPrefsDict;
    filteredPrefsDict = [NSMutableDictionary dictionaryWithDictionary:[preferences dictionaryRepresentationSEB]];
    
    // Write SEB_OS_version_build version information to .seb settings
    NSString *originatorVersion = [NSString stringWithFormat:@"SEB_OSX_%@_%@",
     [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"],
                                   [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"]];
    [filteredPrefsDict setObject:originatorVersion forKey:@"originatorVersion"];

    // Remove copy Browser Exam Key to clipboard when quitting flag when saving for starting exams
    if ([sebPurpose selectedRow] == sebConfigPurposeStartingExam) {
        [filteredPrefsDict removeObjectForKey:@"copyBrowserExamKeyToClipboardWhenQuitting"];
    }

    // Convert preferences directory to XML property list
    NSError *error;
    NSData *dataRep = [NSPropertyListSerialization dataWithPropertyList:filteredPrefsDict
                                                                 format:NSPropertyListXMLFormat_v1_0
                                                                options:0
                                                                  error:&error];

    NSMutableString *sebXML = [[NSMutableString alloc] initWithData:dataRep encoding:NSUTF8StringEncoding];
#ifdef DEBUG
    NSLog(@".seb XML plist: %@", sebXML);
#endif
    
    /*/ Remove property list XML header
    NSRange rootDictOpeningTag = [sebXML rangeOfString:@"<dict>"];
    NSRange headerRange;
    headerRange.location = 0;
    headerRange.length = rootDictOpeningTag.location;
    [sebXML deleteCharactersInRange:headerRange];
    
    // Remove property list XML footer
    NSRange footerRange = [sebXML rangeOfString:@"</plist>" options:NSBackwardsSearch];
    footerRange.length = sebXML.length - footerRange.location;
    [sebXML deleteCharactersInRange:footerRange];
    
#ifdef DEBUG
    NSLog(@".seb XML after striping header and footer: %@", sebXML);
#endif
    */
    NSData *encryptedSebData = [sebXML dataUsingEncoding:NSUTF8StringEncoding];
    //NSData *encryptedSebData = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];

    NSString *encryptingPassword = nil;

    // Check for special case: .seb configures client, empty password
    if (!settingsPassword && [sebPurpose selectedRow] == 1) {
        encryptingPassword = @"";
    } else {
        // in all other cases:
        // Check if no password entered and no identity selected
        if (!settingsPassword && ![chooseIdentity indexOfSelectedItem]) {
            NSRunAlertPanel(NSLocalizedString(@"No encryption chosen", nil),
                            NSLocalizedString(@"You have to either enter a password or choose a cryptographic identity with which the SEB settings file will be encrypted.", nil),
                            NSLocalizedString(@"OK", nil), nil, nil);
            return;
        }
    }
    // Check if password for encryption is entered
    if (settingsPassword) {
        encryptingPassword = settingsPassword;
    }
    // So if password is empty (special case) or entered
    if (encryptingPassword) {
        // encrypt with password
        encryptedSebData = [self encryptData:encryptedSebData usingPassword:encryptingPassword];
    } else {
        // if no encryption with password: add a spare 4-char prefix identifying plain data
        const char *utfString = [@"plnd" UTF8String];
        NSMutableData *encryptedData = [NSMutableData dataWithBytes:utfString length:4];
        //append plain data
        [encryptedData appendData:encryptedSebData];
        encryptedSebData = [NSData dataWithData:encryptedData];
    }
    // Check if cryptographic identity for encryption is selected
    if ([chooseIdentity indexOfSelectedItem]) {
        // Encrypt preferences using a cryptographic identity
        encryptedSebData = [self encryptDataUsingSelectedIdentity:encryptedSebData];
    }
        
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


// Encrypt preferences using a certificate
- (NSData*) encryptDataUsingSelectedIdentity:(NSData*)data {
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    
    //get certificate from selected identity
    NSUInteger selectedIdentity = [chooseIdentity indexOfSelectedItem]-1;
    SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity]);
    SecCertificateRef certificateRef = [keychainManager getCertificateFromIdentity:identityRef];
    
    //get public key hash from selected identity's certificate
    NSData* publicKeyHash = [keychainManager getPublicKeyHashFromCertificate:certificateRef];
    
    //encrypt data using public key
    NSData *encryptedData = [keychainManager encryptData:data withPublicKeyFromCertificate:certificateRef];
    
    // Test decryption
    /*SecKeyRef privateKeyRef = [keychainManager privateKeyFromIdentity:&identityRef];
    NSData *decryptedSebData = [keychainManager decryptData:encryptedData withPrivateKey:privateKeyRef];
    
    // Test
    SecKeyRef privateKeyRef2 = [keychainManager getPrivateKeyFromPublicKeyHash:publicKeyHash];
    NSLog(@"Private key from identity %@ and retrieved with hash: %@", privateKeyRef, privateKeyRef2);
    
    NSMutableDictionary *loadedPrefsDict = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedSebData];
    NSLog(@"Decrypted .seb dictionary: %@",loadedPrefsDict);
    */
    //if (certificateRef) CFRelease(certificateRef);
    
    //Prefix indicating data has been encrypted with a public key identified by hash
    const char *utfString = [@"pkhs" UTF8String];
    NSMutableData *encryptedSebData = [NSMutableData dataWithBytes:utfString length:4];
    //append public key hash
    [encryptedSebData appendData:publicKeyHash];
    //append encrypted data
    [encryptedSebData appendData:encryptedData];

    return encryptedSebData;
}


// Encrypt preferences using a password
- (NSData*) encryptData:(NSData*)data usingPassword:password {
    const char *utfString;
    // Check if .seb file should start exam or configure client
    if ([sebPurpose selectedRow] == 0) {
        // prefix string for starting exam: normal password will be prompted
        utfString = [@"pswd" UTF8String];
    } else {
        // prefix string for configuring client: configuring password will either be admin pw on client
        // or if no admin pw on client set: empty pw //(((or prompt pw before configuring)))
        utfString = [@"pwcc" UTF8String];
        if (![password isEqualToString:@""]) {
            //empty password means no admin pw on clients and should not be hashed
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            password = [keychainManager generateSHAHashString:password];
        }
    }
    NSMutableData *encryptedSebData = [NSMutableData dataWithBytes:utfString length:4];
    NSError *error;
    NSData *encryptedData = [RNEncryptor encryptData:data
                                        withSettings:kRNCryptorAES256Settings
                                            password:password
                                               error:&error];;
    [encryptedSebData appendData:encryptedData];
    
    return encryptedSebData;
}

@end
