//
//  SEBInAppSettingsViewController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.10.18.
//

#import "SEBInAppSettingsViewController.h"
#import "CustomViewCell.h"


@interface SEBInAppSettingsViewController ()

@end


@implementation SEBInAppSettingsViewController

- (id)init {
    self = [super init];
    if (self) {
        _customCells = [NSMutableDictionary new];
        
        // Register notification for changed keys
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(settingsChanged)
                                                     name:kIASKAppSettingChanged
                                                   object:nil];
        
        // If identities aren't available yet, get them from Keychain
        if (!self.identitiesNames) {
            SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
            NSArray *names;
            NSArray *identitiesInKeychain = [keychainManager getIdentitiesAndNames:&names];
            self.identities = identitiesInKeychain;
            self.identitiesNames = [NSMutableArray arrayWithObject:NSLocalizedString(@"None", nil)];;
            [self.identitiesNames addObjectsFromArray:names];
            _identitiesCounter = [NSMutableArray new];
            for (NSUInteger ruleCounter = 0; ruleCounter < self.identitiesNames.count; ruleCounter++) {
                [_identitiesCounter addObject:([NSNumber numberWithUnsignedInteger:ruleCounter])];
                ruleCounter++;
            }
        }

        // Display current keys
        [self displayBrowserExamKey];
        [self displayConfigKey];
        
    }
    return self;
}


- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [sender dismissViewControllerAnimated:YES completion:^{
        [self->_sebViewController settingsViewControllerDidEnd:sender];
    }];
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
        return self.identitiesCounter;
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
        return self.identitiesNames;
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


- (void)settingsChanged
{
    [[NSUserDefaults standardUserDefaults] setSecureObject:[NSDictionary dictionary]
                                                    forKey:@"org_safeexambrowser_configKeyContainedKeys"];
    [[SEBCryptor sharedSEBCryptor] updateEncryptedUserDefaults:YES updateSalt:NO];
    // Display updated or current keys
    [self displayBrowserExamKey];
    [self displayConfigKey];
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
