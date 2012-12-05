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
#import "RNCryptor.h"
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

- (void)willBeDisplayed {
    //[chooseIdentity synchronizeTitleAndSelectedItem];
    if (!self.identitiesName) { //no identities available yet, get them from keychain
        //first display placeholder in popupbutton list
        //[chooseIdentity addItemsWithTitles:[NSArray arrayWithObjects:NSLocalizedString(@"Fetching identities", nil), nil]];
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
        [chooseIdentity addItemsWithTitles: self.identitiesName];
    }
}

// Action saving current preferences to a plist-file in application bundle Contents/Resources/ directory
- (IBAction) saveSEBPrefs:(id)sender {
    //[self savePrefs:self];	//save preferences (which are not saved automatically by bindings)
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
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];
    
    // Remove prefix "org_safeexambrowser_SEB_" from keys
    for (NSString *key in filteredPrefsSet) {
        [filteredPrefsDict setObject:[preferences secureObjectForKey:key] forKey:[key substringFromIndex:24]];
    }
    
    // Encrypt preferences using a certificate
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    
    //SecIdentityRef identityRef = (__bridge SecIdentityRef)[identitiesInKeychain objectAtIndex:i];
    NSUInteger selectedIdentity = [chooseIdentity indexOfSelectedItem];
    SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity]);
    SecCertificateRef certificateRef;
    SecIdentityCopyCertificate(identityRef, &certificateRef);

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];
    /*/ Encrypt preferences using a password
    const char *utfString = [@"pw" UTF8String];
    NSMutableData *encryptedSebData = [NSMutableData dataWithBytes:utfString length:2];
    NSError *error;
    NSData *encryptedData = [[RNCryptor AES256Cryptor] encryptData:data password:@"password" error:&error];
    [encryptedSebData appendData:encryptedData];
    */
    
    NSData *encryptedSebData = [keychainManager encryptData:data withPublicKeyFromCertificate:certificateRef];

    // Test decryption
    SecKeyRef privateKeyRef = [keychainManager privateKeyFromIdentity:&identityRef];
    NSData *decryptedSebData = [keychainManager decryptData:encryptedSebData withPrivateKey:privateKeyRef];
    NSLog(@"Decrypted .seb file: %@",decryptedSebData);
    NSMutableDictionary *loadedPrefsDict = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedSebData];
    NSLog(@"Decrypted .seb dictionary: %@",loadedPrefsDict);

    if (certificateRef) CFRelease(certificateRef);
    //if (identityRef) CFRelease(identityRef);
    if (privateKeyRef) CFRelease(privateKeyRef);

    // Save initialValues to a SEB preferences file into the application bundle
    
    // Build a new name for the file using the current name and
    // the filename extension associated with the specified UTI.
    //CFStringRef newExtension = UTTypeCopyPreferredTagWithClass((CFStringRef)@"org.safeexambrowser.seb", kUTTagClassFilenameExtension);
    //NSString* newExtension = @"seb";
    //NSString* newName = [NSLocalizedString(@"Untitled", nil) stringByAppendingPathExtension:(NSString*)newExtension];
    //CFRelease(newExtension);
    
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


@end
