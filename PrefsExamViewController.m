//
//  PrefsExamViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 15.11.12.
//
//

#import "PrefsExamViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "RNCryptor.h"
#import "SEBKeychainManager.h"

@interface PrefsExamViewController ()

@end

@implementation PrefsExamViewController
@synthesize examKey;


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
    NSArray *certificatesInKeychain = [keychainManager getCertificates];
    //SecCertificateRef certificate;
    int i, count = [certificatesInKeychain count];
    SecKeyRef *publicKeyETH = NULL;
    SecCertificateRef certificateETH = NULL;
    SecIdentityRef *identityRefETH = NULL;
    for (i=0; i<count; i++) {
        SecCertificateRef certificate = (__bridge SecCertificateRef)([certificatesInKeychain objectAtIndex:i]);
        SecKeyRef *key = [keychainManager copyPublicKeyFromCertificate:certificate];
        SecIdentityRef *identityRef = [keychainManager createIdentityWithCertificate:certificate];
        NSString *publicKey = (key ? @"found" : @"not found");
        NSString *privateKey = (identityRef ? @"found" : @"not found");
        CFStringRef commonName = NULL;
        SecCertificateCopyCommonName(certificate, &commonName);
        //if ([(__bridge NSString *)commonName isEqualToString:@"3rd Party Mac Developer Installer: Daniel Schneider"]) {
        if ([(__bridge NSString *)commonName isEqualToString:@"ETH Zuerich"]) {
            publicKeyETH = key;
            certificateETH = certificate;
            identityRefETH = identityRef;
        }
#ifdef DEBUG
        NSLog(@"Common name = %@, public key = %@, private key = %@", (__bridge NSString *)commonName, publicKey, privateKey);
#endif
        if (commonName) CFRelease(commonName);
    }
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict];
    /*/ Encrypt preferences using a password
    const char *utfString = [@"pw" UTF8String];
    NSMutableData *encryptedSebData = [NSMutableData dataWithBytes:utfString length:2];
    NSError *error;
    NSData *encryptedData = [[RNCryptor AES256Cryptor] encryptData:data password:@"password" error:&error];
    [encryptedSebData appendData:encryptedData];
    */
    
    //NSData *encryptedSebData = [keychainManager encryptData:data withPublicKey:publicKeyETH];
    NSData *encryptedSebData = [keychainManager encryptData:data withPublicKeyFromCertificate:certificateETH];

    // Test decryption
    SecKeyRef privateKey = [keychainManager privateKeyFromIdentity:identityRefETH];
    NSData *decryptedSebData = [keychainManager decryptData:encryptedSebData withPrivateKey:privateKey];
    NSLog(@"Decrypted .seb file: %@",decryptedSebData);
    NSMutableDictionary *loadedPrefsDict = [NSKeyedUnarchiver unarchiveObjectWithData:decryptedSebData];
    NSLog(@"Decrypted .seb dictionary: %@",loadedPrefsDict);
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
                              NSRunAlertPanel(NSLocalizedString(@"Writing Settings Succeeded", nil), NSLocalizedString(@"WritingToAppBundleSucceeded", nil), NSLocalizedString(@"OK", nil), nil, nil);
                          }
                      }
                  }];
}


@end
