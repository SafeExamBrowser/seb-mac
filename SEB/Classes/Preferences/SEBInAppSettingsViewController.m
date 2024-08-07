//
//  SEBInAppSettingsViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBInAppSettingsViewController.h"
#import "CustomViewCell.h"
#import "SEBUIUserDefaultsController.h"


@implementation SEBInAppSettingsViewController


- (id)initWithIASKAppSettingsViewController:(IASKAppSettingsViewController *)appSettingsViewController sebViewController:(SEBViewController *)sebViewController {
    self = [super init];
    if (self) {
        _appSettingsViewController = appSettingsViewController;
        _sebViewController = sebViewController;
        _permanentSettingsChanged = NO;
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

        // Select identity for passed identity reference
        [self selectSettingsIdentity];

        // Set current keys
        [self displayBrowserExamKey];
        [self displayConfigKey];

        // Set visibility of keys dependent on specific settings
        [self setAllDependentKeys];
        
        [self initTextFieldValues];
    }
    return self;
}


// Get identites from Keychain
- (void)getIdentitiesFromKeychain
{
    NSArray *names;
    NSArray *identitiesInKeychain = [self.keychainManager getIdentitiesAndNames:&names];
    self.identities = identitiesInKeychain;
    self.identitiesNames = [NSMutableArray arrayWithObject:NSLocalizedString(@"Create New…", @"")];;
    [self.identitiesNames addObjectsFromArray:names];
    _identitiesCounter = [NSMutableArray new];
    for (NSUInteger ruleCounter = 0; ruleCounter < self.identitiesNames.count; ruleCounter++) {
        [_identitiesCounter addObject:([NSNumber numberWithUnsignedInteger:ruleCounter])];
    }
    _configFileIdentitiesNames = _identitiesNames.mutableCopy;
    _configFileIdentitiesCounter = _identitiesCounter.mutableCopy;
    _configFileIdentitiesNames[0] = NSLocalizedString(@"None", @"");
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
                    combinedCertificateString = NSLocalizedString(@"SSL", @"");
                    break;
                    
                case certificateTypeIdentity:
                    combinedCertificateString = NSLocalizedString(@"IDENTITY", @"");
                    break;
                    
                case certificateTypeCA:
                    combinedCertificateString = NSLocalizedString(@"CA", @"");
                    break;
                    
                case certificateTypeSSLDebug:
                    combinedCertificateString = NSLocalizedString(@"DEBUG", @"");
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

- (CGFloat)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController heightForSpecifier:(IASKSpecifier *)specifier
{
    if ([specifier.key isEqualToString:@"browserExamKey"]) {
        if (_configModified) {
            _configModified = NO;
            run_on_ui_thread(^{
                [self setDependentKeysForPermanentSettingsChanged];
            });
        }
        return 44;
    }
    if ([specifier.key isEqualToString:@"configKey"]) {
        return 44;
    }
    if ([specifier.key isEqualToString:@"customCell"]) {
        return 44*3;
    }
    return UITableViewAutomaticDimension;
}


- (UITableViewCell*)settingsViewController:(UITableViewController<IASKViewController> *)settingsViewController cellForSpecifier:(IASKSpecifier*)specifier
 {
     if ([specifier.parentSpecifier.key isEqualToString:@"org_safeexambrowser_SEB_permittedProcesses"]) {
         NSDictionary *dict = [self.appSettingsViewController.settingsStore objectForSpecifier:specifier];
         UITableViewCell *cell = [settingsViewController.tableView dequeueReusableCellWithIdentifier:@"appCell"];
         if (!cell) {
             cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"appCell"];
         }
         cell.textLabel.text = dict[@"title"];
         NSUInteger os = [dict[@"os"] intValue];
         if (os != operatingSystemiOS) {
             cell.detailTextLabel.text = [SEBUIUserDefaultsController sharedSEBUIUserDefaultsController].org_safeexambrowser_SEB_operatingSystems[os];
         } else {
             cell.detailTextLabel.text = dict[@"identifier"];
         }
         cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
         return cell;
     }
     
    CustomViewCell *cell = (CustomViewCell*)[settingsViewController.tableView dequeueReusableCellWithIdentifier:specifier.key];
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
    [[NSUserDefaults standardUserDefaults] secureObjectForKey:specifier.key] : NSLocalizedString(@"Share settings to see Key", @"");
    cell.textView.text = text;
    cell.textView.delegate = self;
    [cell setNeedsLayout];
    return cell;
}


- (BOOL)settingsViewController:(UITableViewController<IASKViewController>*)settingsViewController childPaneIsValidForSpecifier:(IASKSpecifier *)specifier
             contentDictionary:(NSMutableDictionary *)contentDictionary {
    if ([specifier.parentSpecifier.key isEqualToString:@"org_safeexambrowser_SEB_permittedProcesses"]) {
        if (contentDictionary[@"os"] == nil) {
            [contentDictionary setValue:[NSNumber numberWithLong:operatingSystemiOS] forKey:@"os"];
        }
        if (contentDictionary[@"active"] == nil) {
            [contentDictionary setValue:[NSNumber numberWithBool:YES] forKey:@"active"];
        }
        return [contentDictionary[@"title"] length] > 1 && ((([contentDictionary[@"os"] intValue] == operatingSystemiOS) && [contentDictionary[@"identifier"] length]) || (([contentDictionary[@"os"] intValue] == operatingSystemMacOS) && [contentDictionary[@"identifier"] length]));
    }
    return YES;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:kIASKAppSettingChanged object:self userInfo:@{@"browserExamKey" : textView.text}];
}


- (IASKValidationResult)settingsViewController:(IASKAppSettingsViewController*)settingsViewController validateSpecifier:(IASKSpecifier*)specifier textField:(IASKTextField*)textField previousValue:(nullable NSString*)previousValue replacement:(NSString* _Nonnull __autoreleasing *_Nullable)replacement
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    IASKValidationResult validationResult = IASKValidationResultOk;
    NSString *newDefaultZoomLevelString = ((UITextField *)textField).text;

    /// User Interface
    if ([specifier.key isEqualToString:@"org_safeexambrowser_defaultPageZoomLevel"]) {
        double newDefaultPageZoomLevel = [self validateZoomLevel:newDefaultZoomLevelString previousValue:previousValue defaultZoomLevel:WebViewDefaultPageZoom minZoomLevel:WebViewMinPageZoom maxZoomLevel:WebViewMaxPageZoom validationResult:&validationResult];
        [preferences setSecureDouble:newDefaultPageZoomLevel forKey:@"org_safeexambrowser_SEB_defaultPageZoomLevel"];
        NSNumber *defaultPageZoomLevel = [NSNumber numberWithDouble:newDefaultPageZoomLevel];
        newDefaultZoomLevelString = [defaultPageZoomLevel stringValue];
        *replacement = newDefaultZoomLevelString;
    }
    
    if ([specifier.key isEqualToString:@"org_safeexambrowser_defaultTextZoomLevel"]) {
        double newDefaultTextZoomLevel = [self validateZoomLevel:newDefaultZoomLevelString previousValue:previousValue defaultZoomLevel:WebViewDefaultTextZoom minZoomLevel:WebViewMinTextZoom maxZoomLevel:WebViewMaxTextZoom validationResult:&validationResult];
        [preferences setSecureDouble:newDefaultTextZoomLevel forKey:@"org_safeexambrowser_SEB_defaultTextZoomLevel"];
        NSNumber *defaultTextZoomLevel = [NSNumber numberWithDouble:newDefaultTextZoomLevel];
        newDefaultZoomLevelString = [defaultTextZoomLevel stringValue];
        *replacement = newDefaultZoomLevelString;
    }

    return validationResult;
}

- (double)validateZoomLevel:(NSString *)newDefaultPageZoomLevelString previousValue:(nullable NSString*)previousValue defaultZoomLevel:(double)defaultZoomLevel minZoomLevel:(double)minZoomLevel maxZoomLevel:(double)maxZoomLevel validationResult:(IASKValidationResult *)validationResult
{
    double newDefaultPageZoomLevel = WebViewDefaultPageZoom;
    NSNumberFormatter *numberFormatter = [NSNumberFormatter new];
    if ([numberFormatter numberFromString:newDefaultPageZoomLevelString] == nil) {
        newDefaultPageZoomLevelString = previousValue;
        *validationResult = IASKValidationResultFailedWithShake;
    }
    if (![[newDefaultPageZoomLevelString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:newDefaultPageZoomLevelString]) {
        *validationResult = IASKValidationResultFailed;
    }

    if (newDefaultPageZoomLevelString.length == 0) {
        newDefaultPageZoomLevelString = previousValue;
        *validationResult = IASKValidationResultFailedWithShake;
    }

    newDefaultPageZoomLevel = newDefaultPageZoomLevelString.doubleValue;
    if (newDefaultPageZoomLevel < WebViewMinPageZoom) {
        newDefaultPageZoomLevel = WebViewMinPageZoom;
        *validationResult = IASKValidationResultFailedWithShake;
    } else if (newDefaultPageZoomLevel > WebViewMaxPageZoom) {
        newDefaultPageZoomLevel = WebViewMaxPageZoom;
        *validationResult = IASKValidationResultFailedWithShake;
    }
    return newDefaultPageZoomLevel;
}


- (void)initTextFieldValues
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    double defaultPageZoomLevel = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_defaultPageZoomLevel"];
    NSString *defaultPageZoomLevelString = [[NSNumber numberWithDouble:defaultPageZoomLevel] stringValue];
    [preferences setSecureString:defaultPageZoomLevelString forKey:@"org_safeexambrowser_defaultPageZoomLevel"];
    
    double defaultTextZoomLevel = [preferences secureDoubleForKey:@"org_safeexambrowser_SEB_defaultTextZoomLevel"];
    NSString *defaultTextZoomLevelString = [[NSNumber numberWithDouble:defaultTextZoomLevel] stringValue];
    [preferences setSecureString:defaultTextZoomLevelString forKey:@"org_safeexambrowser_defaultTextZoomLevel"];
}


- (void)settingsChanged:(NSNotification *)notification
{
    NSArray *changedKeys = [notification.userInfo allKeys];
    DDLogDebug(@"Changed settings keys: %@", changedKeys);
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    // Check if permanent SEB settings (which are exported) changed
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@", sebUserDefaultsPrefix];
    NSArray *results = [changedKeys filteredArrayUsingPredicate:predicate];
    if (results.count > 0) {
        // Key/values of permanent SEB settings changed: We reset the contained keys array
        // so all keys of current SEB settings will be contained in the Config Key
        // This alters the Browser Exam and Config Key of opened settings, so if you share those,
        // you need to update the config file when it is for example saved on a server
        if (_permanentSettingsChanged == NO) {
            _permanentSettingsChanged = YES;
            _configModified = YES;
        }
        [preferences setSecureObject:[NSDictionary dictionary]
                              forKey:@"org_safeexambrowser_configKeyContainedKeys"];
        _sebViewController.browserController.browserExamKey = nil;
        _sebViewController.browserController.configKey = nil;
        // Force recalculating Config Key
        [preferences setSecureObject:nil forKey:@"org_safeexambrowser_configKey"];
        [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
        // Display updated or current keys
        [self displayBrowserExamKey];
        [self displayConfigKey];
    }
        // Otherwise only temporary SEB settings (prefix "org_safeexambrowser_") changed,
        // then we don't alter the Browser Exam and Config Keys

    /// Config File
    
    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_sebConfigPurpose"] ||
        [changedKeys containsObject:@"org_safeexambrowser_shareConfigFormat"]) {
        [self setDependentKeysForSEBConfigPurpose];
    }
    
    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_sebConfigPurpose"]) {
        [self setDependentKeysForShareAs];
    }
    
    if ([changedKeys containsObject:@"org_safeexambrowser_shareConfigFormat"]) {
        [self setDependentKeysForRemoveDefaults];
    }
    
    if ([changedKeys containsObject:@"org_safeexambrowser_configFileIdentity"]) {
        [self setDependentKeysForPlainText];
        [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
    }
    
    // Create & Embed Identity enabled
    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_configFileCreateIdentity"] &&
        [preferences secureBoolForKey:@"org_safeexambrowser_SEB_configFileCreateIdentity"]) {
        // Get a default config identity name derived from the current config file name
        NSString *identityName = [self getConfigFileIdentityName];
        NSData *identityData = [self.keychainManager generatePKCS12IdentityWithName:identityName];
        if (identityData) {
            if ([self.keychainManager importIdentityFromData:identityData]) {
                if ([self embedPKCS12Identity:identityData name:identityName]) {
                    self->_embeddedCertificatesList = nil;
                    self->_embeddedCertificatesListCounter = nil;
                    
                    [self getIdentitiesFromKeychain];
                    // Hide the PSMultiValueSpecifier list and unhide it again, this is a
                    // workaround to refresh the list of embedded certificates
                    NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
                    NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
                    [newHiddenKeys addObject: @"org_safeexambrowser_configFileIdentity"];
                    [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
                    [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
                }
            }
        }
    }

    if ([changedKeys containsObject:@"org_safeexambrowser_settingsPassword"]) {
        [self setDependentKeysForPlainText];
    }
    
    
    /// Browser Features

    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_browserMediaAutoplay"]) {
        [self setDependentKeysForBrowserMediaAutoplay];
    }
   
    
    /// Down/Uploads

    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_allowDownUploads"]) {
        [self setDependentKeysForAllowDownUploads];
    }
   
    
    /// Exam Session
    
    // Check if "Use Browser and Config Keys" was selected
    if ([changedKeys containsObject:@"org_safeexambrowser_SEB_sendBrowserExamKey"]) {
        [self setDependentKeysForSendBrowserExamKey];
    }
    
    if ([changedKeys containsObject:@"org_safeexambrowser_configFileShareBrowserExamKey"] ||
        [changedKeys containsObject:@"org_safeexambrowser_configFileShareConfigKey"]) {
        [self setDependentKeysForShareKeys];
    }
    
    
    /// Network / Certificates
    
    // Check if an identity to embed was selected (Settings/Network/Certificates/Choose Identity)
    if ([changedKeys containsObject:@"org_safeexambrowser_chooseIdentityToEmbed"]) {
        NSUInteger indexOfSelectedIdentity = [preferences secureIntegerForKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
        
        // "Create New…" selected
        if (indexOfSelectedIdentity == 0) {
            // Get a default idenity name derived from the current config file name
            NSString *identityName = [self getConfigFileIdentityName];
            [self createNewIdentityRequestName:identityName];
            
        } else if (indexOfSelectedIdentity > 0) {
            // Identity selected
            SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:indexOfSelectedIdentity-1]);

            // Show alert to choose if identity should be embedded or removed from keychain
            NSString *identityMessage = NSLocalizedString(@"Embed the identity certificate '%@' into a client config file and use that to configure exam devices. Then you can encrypt exam config files with the identity (see Configuration page).", @"");
            NSString *identityName = self.identitiesNames[indexOfSelectedIdentity];
            identityMessage = [NSString stringWithFormat:identityMessage, identityName];
            [_sebViewController alertWithTitle:NSLocalizedString(@"Identity in Keychain", @"")
                                       message:identityMessage
                                preferredStyle:UIAlertControllerStyleAlert
                                  action1Title:NSLocalizedString(@"Remove", @"")
                                  action1Style:UIAlertActionStyleDestructive
                                action1Handler:^{
                                    [self.sebViewController alertWithTitle:NSLocalizedString(@"Confirm Removing Identity", @"")
                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"If you remove the identity '%@' from the Keychain and you don't have a copy (embedded in a config file or installed on another device), then you cannot decrypt exam config files encrypted with this identity anymore.", @""), identityName]
                                                            preferredStyle:UIAlertControllerStyleAlert
                                                              action1Title:NSLocalizedString(@"Remove", @"")
                                                              action1Style:UIAlertActionStyleDestructive
                                                            action1Handler:^{
                                                                if (![self.keychainManager removeIdentityFromKeychain:identityRef]) {
                                                                    [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                    [self.sebViewController alertWithTitle:NSLocalizedString(@"Removing Identity Failed!", @"")
                                                                                                   message:[NSString stringWithFormat:NSLocalizedString(@"The identity '%@' could not be removed from the Keychain.", @""), identityName]
                                                                                              action1Title:NSLocalizedString(@"OK", @"")
                                                                                            action1Handler:^{
                                                                                                [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                                            }
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
                                                              action2Title:NSLocalizedString(@"Cancel", @"")
                                                              action2Style:UIAlertActionStyleCancel
                                                            action2Handler:^{
                                                                [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                            }];
                                    
                                }
                                  action2Title:NSLocalizedString(@"Embed", @"")
                                  action2Style:UIAlertActionStyleDefault
                                action2Handler:^{
                                    NSData *identityAdminPasswordHash = [self.keychainManager retrieveKeyForIdentity:identityRef];
                                    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
                                    NSData *adminPasswordHash = [[preferences secureStringForKey:@"org_safeexambrowser_SEB_hashedAdminPassword"].uppercaseString dataUsingEncoding:NSUTF8StringEncoding];

                                    // Check if the identity was stored using the same SEB admin password
                                    // as the one used in current settings
                                    if (identityAdminPasswordHash.length > 0 && ![identityAdminPasswordHash isEqualToData:adminPasswordHash]) {
                                        [self embedIdentityRequestAdminPassword:identityRef name:identityName adminPasswordHash:identityAdminPasswordHash];
                                    } else {
                                        [self embedIdentity:identityRef name:identityName];
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
                                        NSLocalizedString(@"Name", @""),
                                        certificateName,
                                        NSLocalizedString(@"Type", @""),
                                        certficateType];
        
        [_sebViewController alertWithTitle:NSLocalizedString(@"Embedded Certificate", @"")
                                   message:certificateMessage
                            preferredStyle:UIAlertControllerStyleAlert
                              action1Title:NSLocalizedString(@"Remove", @"")
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
                              action2Title:NSLocalizedString(@"OK", @"")
                              action2Style:UIAlertActionStyleDefault
                            action2Handler:^{
                                [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_embeddedCertificatesList"];
                                [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                            }];
    }
    
     
     /// Security

     if ([changedKeys containsObject:@"org_safeexambrowser_SEB_mobileEnableASAM"] ||
         [changedKeys containsObject:@"org_safeexambrowser_SEB_mobileEnableModernAAC"]) {
         [self setDependentKeysForAAC];
     }
}


- (void)setAllDependentKeys
{
    [self setDependentKeysForSEBConfigPurpose];
    [self setDependentKeysForShareAs];
    [self setDependentKeysForRemoveDefaults];
    [self setDependentKeysForBrowserMediaAutoplay];
    [self setDependentKeysForAllowDownUploads];
    [self setDependentKeysForSendBrowserExamKey];
    [self setDependentKeysForShareKeys];
    [self setDependentKeysForAAC];
    
    // This is necessary because [self setDependentKeysForPermanentSettingsChanged] doesn't work before the Exam Keys pane is actually displayed:
    _configModified = YES;
}


- (void)setDependentKeysForPermanentSettingsChanged
{
    NSSet *dependentKeys = [NSSet setWithArray:@[@"configModifedWarning"]];
    if (_permanentSettingsChanged == NO)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForSEBConfigPurpose
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"autoIdentity",
                                                 @"org_safeexambrowser_SEB_configFileCreateIdentity",
                                                 @"org_safeexambrowser_SEB_configFileEncryptUsingIdentity"]];
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"] == sebConfigPurposeStartingExam)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
    [self setDependentKeysForPlainText];
}


- (void)setDependentKeysForShareAs
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_shareConfigFormat"]];
    if ([preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"] == sebConfigPurposeManagedConfiguration)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForRemoveDefaults
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    ShareConfigFormat shareConfigFormat = [preferences secureIntegerForKey:@"org_safeexambrowser_shareConfigFormat"];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_removeDefaults"]];
    if (shareConfigFormat != shareConfigFormatFile)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForPlainText
{
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_shareConfigUncompressed"]];
    if (![self canSavePlainText])
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (BOOL) canSavePlainText
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    ShareConfigFormat shareConfigFormat = [preferences secureIntegerForKey:@"org_safeexambrowser_shareConfigFormat"];
    BOOL configPurposeStartingExam = [preferences secureIntegerForKey:@"org_safeexambrowser_SEB_sebConfigPurpose"] == sebConfigPurposeStartingExam;
    return shareConfigFormat == shareConfigFormatFile &&
    configPurposeStartingExam &&
    [[NSUserDefaults standardUserDefaults] secureIntegerForKey:@"org_safeexambrowser_configFileIdentity"] == 0 &&
    [[NSUserDefaults standardUserDefaults] secureStringForKey:@"org_safeexambrowser_settingsPassword"].length == 0;
}


- (void)setDependentKeysForBrowserMediaAutoplay
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_SEB_browserMediaAutoplayVideo",
                                                 @"org_safeexambrowser_SEB_browserMediaAutoplayAudio"]];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_browserMediaAutoplay"] == NO)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForAllowDownUploads
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_SEB_allowDownloads",
                                                 @"org_safeexambrowser_SEB_allowUploads"]];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowDownUploads"] == NO)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForSendBrowserExamKey
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"examKeysChildPane"]];
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_sendBrowserExamKey"] == NO)
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        [self setDependentKeysForPermanentSettingsChanged];
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForShareKeys
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_configFileShareKeys"]];
    if (![preferences secureBoolForKey:@"org_safeexambrowser_configFileShareBrowserExamKey"] &&
        ![preferences secureBoolForKey:@"org_safeexambrowser_configFileShareConfigKey"])
    {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
        
    } else {
        NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
        [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    }
}


- (void)setDependentKeysForAAC
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableSet *newHiddenKeys;
    NSSet *dependentKeys = [NSSet setWithArray:@[@"org_safeexambrowser_SEB_mobileEnableModernAAC"]];
    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableASAM"])
    {
         newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        
    } else {
        newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
    }
    [self.appSettingsViewController setHiddenKeys:newHiddenKeys];

    dependentKeys = [NSSet setWithArray:@[@"appsChildPane"]];
    if (![preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableASAM"] ||
        ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_mobileEnableModernAAC"])
    {
        newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys unionSet:dependentKeys];
        
    } else {
        newHiddenKeys = [NSMutableSet setWithSet:self.appSettingsViewController.hiddenKeys];
        [newHiddenKeys minusSet:dependentKeys];
    }
    [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
}


// "Create New…" identity: Get name
- (void)createNewIdentityRequestName:(NSString *)identityName
{
    // Allow the user to edit this derived identity name
    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Create New Identity", @"")
                                                                             message:NSLocalizedString(@"Use the identity name derived from the current config file name or enter another. It has to be unique amongst all identities.", @"")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"Identity Name", @"");
         textField.text = identityName;
         textField.autocorrectionType = UITextAutocorrectionTypeNo;
     }];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                               NSString *identityName = self.sebViewController.alertController.textFields.firstObject.text;
                                                                               self.sebViewController.alertController = nil;
                                                                               if (identityName.length == 0) {
                                                                                   [self.sebViewController alertWithTitle:NSLocalizedString(@"No Identity Name Provided", @"")
                                                                                                              message:NSLocalizedString(@"An identity needs a unique name.", @"")
                                                                                                         action1Title:NSLocalizedString(@"OK", @"")
                                                                                                       action1Handler:^{
                                                                                                           [self createNewIdentityRequestName:[self getConfigFileIdentityName]];
                                                                                                       }
                                                                                                         action2Title:NSLocalizedString(@"Cancel", @"")
                                                                                                       action2Handler:^{
                                                                                                           [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                                                           [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                                                       }];
                                                                               } else if ([self.identitiesNames containsObject:identityName]) {
                                                                                   [self.sebViewController alertWithTitle:NSLocalizedString(@"Identity Name Not Unique", @"")
                                                                                                                  message:NSLocalizedString(@"An identity with the same name is already stored in the Keychain. Please use a unique name.", @"")
                                                                                                             action1Title:NSLocalizedString(@"OK", @"")
                                                                                                           action1Handler:^{
                                                                                                               [self createNewIdentityRequestName:[self getConfigFileIdentityName]];
                                                                                                           }
                                                                                                             action2Title:NSLocalizedString(@"Cancel", @"")
                                                                                                           action2Handler:^{
                                                                                                               [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                                                               [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                                                           }];
                                                                               } else {
                                                                                   [self createNewIdentityWithName:identityName];
                                                                               }
                                                                           }]];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                           style:UIAlertActionStyleCancel
                                                                         handler:^(UIAlertAction *action) {
                                                                               self.sebViewController.alertController = nil;
                                                                             [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                             [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                           }]];

    [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];

    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
}


// Get a name for a generated identity derived from the current config file name
- (NSString *)getConfigFileIdentityName
{
    NSString *configFileName = [[[NSUserDefaults standardUserDefaults] secureStringForKey:@"configFileName"]
                                stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (configFileName.length == 0) {
        configFileName = [NSString stringWithFormat:@"%@ Config", SEBShortAppName];
    }
    configFileName = [NSString stringWithFormat:@"%@ %@", configFileName, NSLocalizedString(@"Identity", @"")];
    return configFileName;
}


- (void)createNewIdentityWithName:(NSString *)configFileName
{
    [self.keychainManager generateIdentityWithName:configFileName];

    [self getIdentitiesFromKeychain];
    
    // Hide the PSMultiValueSpecifier list and unhide it again, this is a
    // workaround to refresh the list of embedded certificates
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
    NSSet *currentlyHiddenKeys = self.appSettingsViewController.hiddenKeys;
    NSMutableSet *newHiddenKeys = [NSMutableSet setWithSet:currentlyHiddenKeys];
    [newHiddenKeys addObject: @"org_safeexambrowser_embeddedCertificatesList"];
    [self.appSettingsViewController setHiddenKeys:newHiddenKeys];
    [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
    [self.appSettingsViewController setHiddenKeys:currentlyHiddenKeys];
}


- (void)embedIdentity:(SecIdentityRef)identityRef name:(NSString *)identityName
{
    // Get PKCS12 data representation of selected identity
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *identityData = [self.keychainManager getDataForIdentity:identityRef];
    if (identityData) {
        if ([self embedPKCS12Identity:identityData name:identityName]) {
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
        }
    } else {
        [preferences setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
        [self.sebViewController alertWithTitle:NSLocalizedString(@"Could not Export Identity", @"")
                                       message:NSLocalizedString(@"The private key and certificate contained in the selected identity could not be exported. Try another identity.", @"")
                                  action1Title:NSLocalizedString(@"OK", @"")
                                action1Handler:^{}
                                  action2Title:nil
                                action2Handler:^{}];
    }
}


// "Create New…" identity: Get name
- (void)embedIdentityRequestAdminPassword:(SecIdentityRef)identityRef name:(NSString *)identityName adminPasswordHash:(NSData *)identityAdminPasswordHash
{
    if (_sebViewController.alertController) {
        [_sebViewController.alertController dismissViewControllerAnimated:NO completion:nil];
    }
    _sebViewController.alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Enter Identity Admin Password", @"")
                                                                             message:[NSString stringWithFormat:NSLocalizedString(@"This identity was stored to the Keychain while using a different %@ admin password than currently set. Enter the admin password associated with the identity:", @""), SEBShortAppName]
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [_sebViewController.alertController addTextFieldWithConfigurationHandler:^(UITextField *textField)
     {
         textField.placeholder = NSLocalizedString(@"Admin Password", @"");
         textField.secureTextEntry = YES;
     }];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"")
                                                                           style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                                                               NSString *enteredAdminPassword = self.sebViewController.alertController.textFields.firstObject.text;
                                                                               NSData *enteredAdminPasswordHash = [[self.keychainManager generateSHAHashString:enteredAdminPassword].uppercaseString dataUsingEncoding:NSUTF8StringEncoding];

                                                                               self.sebViewController.alertController = nil;
                                                                               if (enteredAdminPasswordHash.length > 0 && ![identityAdminPasswordHash isEqualToData:enteredAdminPasswordHash]) {
                                                                                   [self.sebViewController alertWithTitle:NSLocalizedString(@"Re-enter Identity Admin Password", @"")
                                                                                                                  message:[NSString stringWithFormat:NSLocalizedString(@"The entered %@ admin password didn't match the one stored for this identity. Try again.", @""), SEBShortAppName]
                                                                                                             action1Title:NSLocalizedString(@"OK", @"")
                                                                                                           action1Handler:^{
                                                                                                               [self embedIdentityRequestAdminPassword:(SecIdentityRef)identityRef name:(NSString *)identityName adminPasswordHash:identityAdminPasswordHash];
                                                                                                           }
                                                                                                             action2Title:NSLocalizedString(@"Cancel", @"")
                                                                                                           action2Handler:^{
                                                                                                               [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                                                               [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                                                           }];
                                                                               } else {
                                                                                   [self embedIdentity:identityRef name:identityName];
                                                                               }
                                                                           }]];
    
    [_sebViewController.alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"")
                                                                           style:UIAlertActionStyleCancel
                                                                         handler:^(UIAlertAction *action) {
                                                                               self.sebViewController.alertController = nil;
                                                                             [[NSUserDefaults standardUserDefaults] setSecureInteger: -1 forKey:@"org_safeexambrowser_chooseIdentityToEmbed"];
                                                                             [self.appSettingsViewController.navigationController popViewControllerAnimated:YES];
                                                                           }]];
    
    [_sebViewController.topMostController presentViewController:_sebViewController.alertController animated:NO completion:nil];
}


- (BOOL)embedPKCS12Identity:(NSData *)identityData name:(NSString *)identityName
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *identityToEmbed = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:certificateTypeIdentity], @"type",
                                     identityName, @"name",
                                     identityData, @"certificateData",
                                     nil];
    
    NSMutableArray *embeddedCertificates = [preferences secureArrayForKey:@"org_safeexambrowser_SEB_embeddedCertificates"].mutableCopy;
    [embeddedCertificates addObject:identityToEmbed];
    [preferences setSecureObject:embeddedCertificates.copy forKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
    return YES;
}


- (void)displayBrowserExamKey
{
    NSData *browserExamKey = _sebViewController.browserController.browserExamKey;
    [self displayKeyHash:browserExamKey key:@"browserExamKey"];
}


- (void)displayConfigKey
{
    NSData *configKey = _sebViewController.browserController.configKey;
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
