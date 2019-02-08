//
//  SEBInAppSettingsViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
//

#import "SEBInAppSettingsViewController.h"
#import "CustomViewCell.h"
#import "SEBUIUserDefaultsController.h"


@interface SEBInAppSettingsViewController ()

@end


@implementation SEBInAppSettingsViewController

- (id)initWithSEBViewController:(SEBViewController *)sebViewController {
    self = [super init];
    if (self) {
        _sebViewController = sebViewController;
        _customCells = [NSMutableDictionary new];
        
        // Register notification for changed keys
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(settingsChanged:)
                                                     name:kIASKAppSettingChanged
                                                   object:nil];
        
        self.keychainManager = [[SEBKeychainManager alloc] init];

        // If identities aren't available yet, get them from Keychain
        if (!self.identitiesNames) {
            [self getIdentitiesFromKeychain];
        }

        // If certificates aren't available yet, get them from Keychain
        if (!self.certificatesNames) {
            NSArray *names;
            NSArray *certificatesInKeychain = [self.keychainManager getCertificatesAndNames:&names];
            self.certificates = certificatesInKeychain;
            self.certificatesNames = [NSMutableArray arrayWithObject:NSLocalizedString(@"None", nil)];;
            [self.certificatesNames addObjectsFromArray:names];
            _certificatesCounter = [NSMutableArray new];
            for (NSUInteger ruleCounter = 0; ruleCounter < self.certificatesNames.count; ruleCounter++) {
                [_certificatesCounter addObject:([NSNumber numberWithUnsignedInteger:ruleCounter])];
            }
        }
        // Select identity for passed identity reference
        [self selectSettingsIdentity];
        // Display current keys
        [self displayBrowserExamKey];
        [self displayConfigKey];
        
    }
    return self;
}


// Get identites from Keychain
- (void)getIdentitiesFromKeychain
{
    NSArray *names;
    NSArray *identitiesInKeychain = [self.keychainManager getIdentitiesAndNames:&names];
    self.identities = identitiesInKeychain;
    self.identitiesNames = [NSMutableArray arrayWithObject:NSLocalizedString(@"Create New…", nil)];;
    [self.identitiesNames addObjectsFromArray:names];
    _identitiesCounter = [NSMutableArray new];
    for (NSUInteger ruleCounter = 0; ruleCounter < self.identitiesNames.count; ruleCounter++) {
        [_identitiesCounter addObject:([NSNumber numberWithUnsignedInteger:ruleCounter])];
    }
    _configFileIdentitiesNames = _identitiesNames.mutableCopy;
    _configFileIdentitiesCounter = _identitiesCounter.mutableCopy;
    _configFileIdentitiesNames[0] = NSLocalizedString(@"None", nil);
}


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender dismissViewControllerAnimated:YES completion:^{
        [self->_sebViewController settingsViewControllerDidEnd:sender];
    }];
}


// Select identity for passed identity reference
- (void) selectSettingsIdentity
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureInteger:0 forKey:@"org_safeexambrowser_configFileIdentity"];

    NSData *settingsPublicKeyHash = _sebViewController.configFileKeyHash;
    if (settingsPublicKeyHash) {
        NSUInteger i, count = [self.identities count];
        for (i=0; i<count; i++) {
            SecIdentityRef identityFromKeychain = (__bridge SecIdentityRef)self.identities[i];
            NSData *publicKeyHash = [self.keychainManager getPublicKeyHashFromIdentity:identityFromKeychain];
            if ([settingsPublicKeyHash isEqualToData:publicKeyHash]) {
                [preferences setSecureInteger:i+1 forKey:@"org_safeexambrowser_configFileIdentity"];
                break;
            }
        }
    }
}


// Select identity for passed identity reference
- (void) selectLatestSettingsIdentity
{
    // Select the last identity certificate from the list
    NSUInteger autoSelectedIdentityCounter = self.identities.count-1;
    if (autoSelectedIdentityCounter >= 0) {
        SecIdentityRef identityFromKeychain = (__bridge SecIdentityRef)self.identities[autoSelectedIdentityCounter];
        _sebViewController.configFileKeyHash = [self.keychainManager getPublicKeyHashFromIdentity:identityFromKeychain];;
        
        [[NSUserDefaults standardUserDefaults] setSecureInteger:autoSelectedIdentityCounter+1
                                                         forKey:@"org_safeexambrowser_configFileIdentity"];
    }
}


// Get SecIdentityRef for selected identity
- (SecIdentityRef) getSelectedIdentity
{
    SecIdentityRef identityRef = NULL;
    // Get selected identity certificate
    NSUInteger selectedIdentity = [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_configFileIdentity"];
    
    if (selectedIdentity > 0) {
        // If an identity is selected, then we get the according SecIdentityRef
        identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:selectedIdentity-1]);
    }
    return identityRef;
}


// Get name of selected identity
- (NSString *) getSelectedIdentityName
{
    // Get selected identity certificate
    NSUInteger selectedIdentity = [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_configFileIdentity"];
    NSString *selectedIdentityName;
    
    if (selectedIdentity > 0) {
        // If an identity is selected, then we get the according SecIdentityRef
        selectedIdentityName = self.identitiesNames[selectedIdentity];
    }
    return selectedIdentityName;
}


- (NSMutableArray *)combinedURLFilterRulesCounter
{
    if (!_combinedURLFilterRulesCounter) {
        _combinedURLFilterRulesCounter = [NSMutableArray new];
    }
    return _combinedURLFilterRulesCounter;
}


- (NSMutableArray *)combinedURLFilterRules
{
    if (!_combinedURLFilterRules) {
        _combinedURLFilterRules = [NSMutableArray new];
        _combinedURLFilterRulesCounter = [NSMutableArray new];
        NSUInteger ruleCounter = 0;
        NSArray *URLFilterRules = [[NSUserDefaults standardUserDefaults] secureArrayForKey:@"org_safeexambrowser_SEB_URLFilterRules"];
        NSDictionary *URLFilterRule;
        
        for (URLFilterRule in URLFilterRules) {
            NSString *combinedFilterString;
            if ([URLFilterRule[@"active"] boolValue]) {
                combinedFilterString = @"☑︎ ";
            } else {
                combinedFilterString = @"☒ ";
            }
            if ([URLFilterRule[@"regex"] boolValue]) {
                combinedFilterString = [NSString stringWithFormat:@"%@ R", combinedFilterString];
            }
            int action = [URLFilterRule[@"action"] intValue];
            switch (action) {
                case URLFilterActionBlock:
                    combinedFilterString = [NSString stringWithFormat:@"%@B ", combinedFilterString];
                    break;
                    
                case URLFilterActionAllow:
                    combinedFilterString = [NSString stringWithFormat:@"%@A ", combinedFilterString];
                    break;
            }
            combinedFilterString = [NSString stringWithFormat:@"%@ %@", combinedFilterString, URLFilterRule[@"expression"]];
            [_combinedURLFilterRules addObject:combinedFilterString];
            [_combinedURLFilterRulesCounter addObject:([NSNumber numberWithUnsignedInteger:ruleCounter])];
            ruleCounter++;
        }
    }
    return _combinedURLFilterRules;
}


- (NSMutableArray *)embeddedCertificatesListCounter
{
    if (!_embeddedCertificatesListCounter) {
        _embeddedCertificatesList = self.embeddedCertificatesList;
    }
    return _embeddedCertificatesListCounter;
}


- (NSMutableArray *)embeddedCertificatesList
{
    if (!_embeddedCertificatesList) {
        _embeddedCertificatesList = [NSMutableArray new];
        _embeddedCertificatesListCounter = [NSMutableArray new];
        NSUInteger certificateCounter = 0;
        NSArray *embeddedCertificates = [[NSUserDefaults standardUserDefaults] secureArrayForKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
        NSDictionary *certificate;
        
        for (certificate in embeddedCertificates) {
            NSString *combinedCertificateString;
            int type = [certificate[@"type"] intValue];
            switch (type) {
                case certificateTypeSSL:
                    combinedCertificateString = NSLocalizedString(@"SSL", nil);
                    break;
                    
                case certificateTypeIdentity:
                    combinedCertificateString = NSLocalizedString(@"IDENTITY", nil);
                    break;
                    
                case certificateTypeCA:
                    combinedCertificateString = NSLocalizedString(@"CA", nil);
                    break;
                    
                case certificateTypeSSLDebug:
                    combinedCertificateString = NSLocalizedString(@"DEBUG", nil);
                    break;
            }
            combinedCertificateString = [NSString stringWithFormat:@"%@  %@", combinedCertificateString, certificate[@"name"]];
            [_embeddedCertificatesList addObject:combinedCertificateString];
            [_embeddedCertificatesListCounter addObject:([NSNumber numberWithUnsignedInteger:certificateCounter])];
            certificateCounter++;
        }
    }
    return _embeddedCertificatesList;
}


#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol

- (CGFloat)tableView:(UITableView*)tableView heightForSpecifier:(IASKSpecifier*)specifier {
    if ([specifier.key isEqualToString:@"browserExamKey"] ||
        [specifier.key isEqualToString:@"configKey"]) {
        return 44;
    }
    return 0;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForSpecifier:(IASKSpecifier*)specifier {
    CustomViewCell *cell = (CustomViewCell*)[tableView dequeueReusableCellWithIdentifier:specifier.key];
    
    if (!cell) {
        cell = (CustomViewCell*)[[[NSBundle mainBundle] loadNibNamed:@"CustomViewCell"
                                                               owner:self
                                                             options:nil] objectAtIndex:0];
    }
    NSString *key = specifier.key;
    if (![_customCells objectForKey:key]) {
        [_customCells setObject:cell forKey:key];
    }
    NSString *text = [[NSUserDefaults standardUserDefaults] secureObjectForKey:key] != nil ?
    [[NSUserDefaults standardUserDefaults] secureObjectForKey:specifier.key] : @"Share settings to see Key";
    cell.textView.text = text;
    cell.textView.delegate = self;
    [cell setNeedsLayout];
    return cell;
}


//
- (NSArray *)settingsViewController:(IASKAppSettingsViewController*)sender valuesForSpecifier:(IASKSpecifier *)specifier {
    if ([specifier.key isEqualToString:@"org_safeexambrowser_configFileIdentity"]) {
        return self.configFileIdentitiesCounter;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_URLFilterRulesCombined"]) {
        return self.combinedURLFilterRulesCounter;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_chooseIdentityToEmbed"]) {
        return self.identitiesCounter;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_embeddedCertificatesList"]) {
        return self.embeddedCertificatesListCounter;
    }
    return nil;
}


- (NSArray *)settingsViewController:(IASKAppSettingsViewController*)sender titlesForSpecifier:(IASKSpecifier *)specifier {
    if ([specifier.key isEqualToString:@"org_safeexambrowser_configFileIdentity"]) {
        return self.configFileIdentitiesNames;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_URLFilterRulesCombined"]) {
        return self.combinedURLFilterRules;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_chooseIdentityToEmbed"]) {
        return self.identitiesNames;
    }
    if ([specifier.key isEqualToString:@"org_safeexambrowser_embeddedCertificatesList"]) {
        return self.embeddedCertificatesList;
    }
    return nil;
}


#pragma mark UITextViewDelegate (for CustomViewCell)
- (void)textViewDidChange:(UITextView *)textView {
//    [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"customCell"];
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:self userInfo:@{@"browserExamKey" : textView.text}];
}


- (void)settingsChanged:(NSNotification *)notification
{
    NSArray *changedKeys = [notification.userInfo allKeys];
    DDLogDebug(@"Changed settings keys: %@", changedKeys);

    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureObject:[NSDictionary dictionary]
                                                    forKey:@"org_safeexambrowser_configKeyContainedKeys"];
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    // Display updated or current keys
    [self displayBrowserExamKey];
    [self displayConfigKey];
    
    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_sebConfigPurpose"]) {
        if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"] == sebConfigPurposeStartingExam) {
            [self.appSettingsViewController setHiddenKeys:[NSSet setWithObjects:@"autoIdentity",
                                                           @"org_safeexambrowser_SEB_configFileCreateIdentity",
                                                           @"org_safeexambrowser_SEB_configFileEncryptUsingIdentity", nil]];
        } else {
            [self.appSettingsViewController setHiddenKeys:nil];
        }
    }
    
    if ([changedKeys containsObject:@"org_safeexambrowser_configFileIdentity"]) {
        [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
    }
    
    // Check if an identity to embed was selected (Settings/Network/Certificates/Choose Identity)
    if ([changedKeys containsObject:@"org_safeexambrowser_chooseIdentityToEmbed"]) {
        NSUInteger indexOfSelectedIdentity = [preferences secureIntegerForKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
        
        // "Create New…" selected
        if (indexOfSelectedIdentity == 0) {
            // Get config file name
            NSString *configFileName = [[preferences secureStringForKey:@"configFileName"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            if (configFileName.length == 0) {
                configFileName = @"SEB Config";
            }
            configFileName = [NSString stringWithFormat:@"%@ %@", configFileName, NSLocalizedString(@"Identity", nil)];
            [self.keychainManager generateIdentityWithName:configFileName];
            [self getIdentitiesFromKeychain];
            
            // Hide the PSMultiValueSpecifier list and unhide it again, this is a
            // workaround to refresh the list of embedded certificates
            [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
            NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
            NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
            [newHiddenKeys addObject: @"org_safeexambrowser_embeddedCertificatesList"];
            [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
            [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
            [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
        }
        // Identity selected
        if (indexOfSelectedIdentity > 0) {
            SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:indexOfSelectedIdentity-1]);

            // Show alert to choose if identity should be embedded or removed from keychain
            NSString *identityMessage = NSLocalizedString(@"Embed the identity certificate '%@' into a client config file and use that to configure exam devices. Then you can encrypt exam config files with the identity (see Config Files page).", nil);
            NSString *identityName = self.identitiesNames[indexOfSelectedIdentity];
            identityMessage = [NSString stringWithFormat:identityMessage, identityName];
            [_sebViewController alertWithTitle:NSLocalizedString(@"Identity in Keychain", nil)
                                       message:identityMessage
                                preferredStyle:UIAlertControllerStyleAlert
                                  action1Title:NSLocalizedString(@"Remove", nil)
                                  action1Style:UIAlertActionStyleDestructive
                                action1Handler:^{
                                    [self.sebViewController alertWithTitle:NSLocalizedString(@"Confirm Removing Identity", nil)
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"If you remove the identity '%@' from the Keychain and you don't have a copy (embedded in a config file, installed on another device or exported), then you cannot decrypt exam config files encrypted with this identity.", nil), identityName]
                                                            preferredStyle:UIAlertControllerStyleAlert
                                                              action1Title:NSLocalizedString(@"Remove", nil)
                                                              action1Style:UIAlertActionStyleDestructive
                                                            action1Handler:^{
                                                                if (![self.keychainManager removeIdentityFromKeychain:identityRef]) {
                                                                    [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                    [self.sebViewController alertWithTitle:NSLocalizedString(@"Removing Identity Failed!", nil)
                                                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"The identity '%@' could not be removed from the Keychain.", nil), identityName]
                                                                                              action1Title:NSLocalizedString(@"OK", nil)
                                                                                            action1Handler:^{}
                                                                                              action2Title:nil
                                                                                            action2Handler:^{}];
                                                                } else {
                                                                    [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                    [self getIdentitiesFromKeychain];
                                                                    
                                                                    // Hide the PSMultiValueSpecifier list and unhide it again, this is a
                                                                    // workaround to refresh the list of embedded certificates
                                                                    NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
                                                                    NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
                                                                    [newHiddenKeys addObject: @"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                    [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
                                                                    [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                    [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
                                                                }
                                                            }
                                                              action2Title:NSLocalizedString(@"Cancel", nil)
                                                              action2Style:UIAlertActionStyleCancel
                                                            action2Handler:^{}];
                                    
                                }
                                  action2Title:NSLocalizedString(@"Embed", nil)
                                  action2Style:UIAlertActionStyleDefault
                                action2Handler:^{
                                    // Get PKCS12 data representation of selected identity
                                    NSData *certificateData = [self.keychainManager getDataForIdentity:identityRef];
                                    if (certificateData) {
                                        NSDictionary *identityToEmbed = [NSDictionary dictionaryWithObjectsAndKeys:
                                                                         [NSNumber numberWithInt:certificateTypeIdentity], @"type",
                                                                         self.identitiesNames[indexOfSelectedIdentity], @"name",
                                                                         certificateData, @"certificateData",
                                                                         nil];
                                        
                                        NSMutableArray *embeddedCertificates = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_embeddedCertificates"].mutableCopy;
                                        [embeddedCertificates addObject:identityToEmbed];
                                        [preferences setSecureObject:embeddedCertificates.copy forKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
                                        self->_embeddedCertificatesList = nil;
                                        self->_embeddedCertificatesListCounter = nil;
                                        
                                        // Hide the PSMultiValueSpecifier list and unhide it again, this is a
                                        // workaround to refresh the list of embedded certificates
                                        [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                        NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
                                        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
                                        [newHiddenKeys addObject: @"org_safeexambrowser_embeddedCertificatesList"];
                                        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
                                        [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                        [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
                                        
                                    } else {
                                        [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                        [self.sebViewController alertWithTitle:NSLocalizedString(@"Could not Export Identity", nil)
                                                                       message:NSLocalizedString(@"The private key and certificate contained in the selected identity could not be exported. Try another identity.", nil)
                                                                  action1Title:NSLocalizedString(@"OK", nil)
                                                                action1Handler:^{}
                                                                  action2Title:nil
                                                                action2Handler:^{}];
                                    }
                                }];
        }
    }
    
    // Check if embedded certificate was selected
    if ([changedKeys containsObject:@"org_safeexambrowser_embeddedCertificatesList"]) {
        NSUInteger indexOfSelectedCertificate = [preferences secureIntegerForKey:@"org_safeexambrowser_embeddedCertificatesList"];
        NSMutableArray *embeddedCertificates = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_embeddedCertificates"].mutableCopy;
        NSDictionary *embeddedCertficate = embeddedCertificates[indexOfSelectedCertificate];
        NSString *certificateName = embeddedCertficate[@"name"];
        certificateName = [certificateName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSNumber *certificateTypeObject = embeddedCertficate[@"type"];
        NSString *certficateType = [[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_certificateTypes][certificateTypeObject.integerValue];
        
        NSString *certificateMessage = [NSString stringWithFormat:@"%@: '%@'\n%@: %@",
                                        NSLocalizedString(@"Name", nil),
                                        certificateName,
                                        NSLocalizedString(@"Type", nil),
                                        certficateType];
        
        [_sebViewController alertWithTitle:NSLocalizedString(@"Embedded Certificate", nil)
                                   message:certificateMessage
                            preferredStyle:UIAlertControllerStyleAlert
                              action1Title:NSLocalizedString(@"Remove", nil)
                              action1Style:UIAlertActionStyleDestructive
                            action1Handler:^{
                                [embeddedCertificates removeObject:embeddedCertficate];
                                [preferences setSecureObject:embeddedCertificates.copy forKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
                                [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_embeddedCertificatesList"];
                                self->_embeddedCertificatesList = nil;
                                self->_embeddedCertificatesListCounter = nil;
                                
                                // Hide the PSMultiValueSpecifier list and unhide it again, this is a
                                // workaround to refresh the list of embedded certificates
                                NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
                                NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
                                [newHiddenKeys addObject: @"org_safeexambrowser_embeddedCertificatesList"];
                                [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
                                [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
                            }
                              action2Title:NSLocalizedString(@"OK", nil)
                              action2Style:UIAlertActionStyleDefault
                            action2Handler:^{
                                [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_embeddedCertificatesList"];
                                [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                            }];
    }
}


- (void)displayBrowserExamKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
    [self displayKeyHash:browserExamKey key:@"browserExamKey"];
}


- (void)displayConfigKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *configKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
    [self displayKeyHash:configKey key:@"configKey"];
}


- (void)displayKeyHash:(NSData *)keyData key:(NSString *)key {
    unsigned char hashedChars[32];
    [keyData getBytes:hashedChars length:32];
    
    NSMutableString* hashedString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < 32 ; ++i) {
        [hashedString appendFormat: @"%02x", hashedChars[i]];
    }
    [[NSUserDefaults standardUserDefaults] setSecureString:hashedString
                                                    forKey:key];
    CustomViewCell *cellForKey = [_customCells objectForKey:key];
    if (cellForKey) {
        [cellForKey.textView setText:hashedString];
    }
}


@end
