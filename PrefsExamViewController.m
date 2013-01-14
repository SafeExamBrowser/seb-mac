//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import "PrefsExamViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "RNEncryptor.h"
#import "SEBKeychainManager.h"

@interface PrefsExamViewController ()

@end

@implementation PrefsExamViewController
@synthesize examKey;
@synthesize identitiesName;
@synthesize identities;


- (NSString *)title
{
	return NSLocalizedString(@"Exam", @"Title of 'Exam' preference pane");
}


- (NSString *)identifier
{
	return @"ExamPane";
}


- (NSImage *)image
{
	return [NSImage imageNamed:@"NSPreferencesGeneral"];
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
    if (!self.identitiesName) { //no identities available yet, get them from keychain
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        NSArray *identitiesInKeychain = [keychainManager getIdentities];
        //SecCertificateRef certificate;
        int i, count = [identitiesInKeychain count];
        self.identitiesName = [NSMutableArray arrayWithCapacity:count];
        SecCertificateRef certificateRef;
        CFStringRef commonName = NULL;
        CFArrayRef emailAddressesRef;
        [self.identitiesName removeAllObjects];
        for (i=0; i<count; i++) {
            SecIdentityRef identityRef = (__bridge SecIdentityRef)[identitiesInKeychain objectAtIndex:i];
            SecIdentityCopyCertificate(identityRef, &certificateRef);
            SecCertificateCopyCommonName(certificateRef, &commonName);
            SecCertificateCopyEmailAddresses(certificateRef, &emailAddressesRef);
            [self.identitiesName addObject:
             [NSString stringWithFormat:@"%@%@",
              (__bridge NSString *)commonName ?
                [NSString stringWithFormat:@"%@ ",(__bridge NSString *)commonName] :
                @"" ,
              CFArrayGetCount(emailAddressesRef) ?
                (__bridge NSString *)CFArrayGetValueAtIndex(emailAddressesRef, 0) :
                @""]
             ];

            if (emailAddressesRef) CFRelease(emailAddressesRef);
            if (commonName) CFRelease(commonName);
            if (certificateRef) CFRelease(certificateRef);
            if (identityRef) CFRelease(identityRef);
        }
        self.identities = identitiesInKeychain;
        [chooseIdentity removeAllItems];
        //first put "None" item in popupbutton list
        [chooseIdentity addItemWithTitle:NSLocalizedString(@"None", nil)];
        [chooseIdentity addItemsWithTitles: self.identitiesName];
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
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"] && ![key isEqualToString:@"org_safeexambrowser_SEB_enablePreferencesWindow"])
                                       return YES;
                                   
                                   else return NO;
                               }];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    
    // Remove prefix "org_safeexambrowser_SEB_" from keys
    for (NSString *key in filteredPrefsSet) {
        if ([key isEqualToString:@"org_safeexambrowser_SEB_downloadDirectory"]) {
            NSString *downloadPath = [preferences secureStringForKey:key];
            // generate a path with a tilde (~) substituted for the full path to the current user’s home directory
            // so that the path is portable to SEB clients with other user's home directories
            downloadPath = [downloadPath stringByAbbreviatingWithTildeInPath];
            [filteredPrefsDict setObject:downloadPath forKey:[key substringFromIndex:24]];
        } else

        [filteredPrefsDict setObject:[preferences secureObjectForKey:key] forKey:[key substringFromIndex:24]];
    }

    // Convert preferences directory to data
    NSData *encryptedSebData = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];

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
                              // Prefs got successfully written to app bundle
                              // Set flag for preferences in app bundle (bindings enable the remove button in prefs same time)
                              NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                              [preferences setSecureObject:[NSNumber numberWithBool:YES] forKey:@"org_safeexambrowser_SEB_prefsInBundle"];
                              NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), NSLocalizedString(@"Encrypted settings have been saved, use this file to start the exam with SEB.", nil), NSLocalizedString(@"OK", nil), nil, nil);
                          }
                      }
                  }];
}


// Encrypt preferences using a certificate
- (NSData*) encryptDataUsingSelectedIdentity:(NSData*)data {
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    
    //get certificate from selected identity
    NSUInteger selectedIdentity = [chooseIdentity indexOfSelectedItem];
    SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity-1]);
    SecCertificateRef certificateRef;
    SecIdentityCopyCertificate(identityRef, &certificateRef);
    
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
    if (certificateRef) CFRelease(certificateRef);
    //if (identityRef) CFRelease(identityRef);
    //if (privateKeyRef) CFRelease(privateKeyRef);
    
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
