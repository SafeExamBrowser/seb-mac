//
//  PrefsNetworkViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 12.02.13.
//  Copyright (c) 2010-2016 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2016 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Network Pane
// Network/Internet settings like URL white/blacklists, certificates and proxy settings

#import "PrefsNetworkViewController.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBKeychainManager.h"
#import "NSURL+SEBURL.h"
#import "SEBURLFilter.h"
#import "SEBURLFilterExpression.h"
#include "x509_crt.h"

@implementation PrefsNetworkViewController

@synthesize groupRowTableColumn;

@synthesize SSLCertificatesNames;
@synthesize SSLCertificates;
@synthesize identitiesNames;
@synthesize identities;


- (NSString *)title
{
	return NSLocalizedString(@"Network", @"Title of 'Network' preference pane");
}

- (NSString *)identifier
{
	return @"NetworkPane";
}

- (NSImage *)image
{
	return [NSImage imageNamed:NSImageNameNetwork];
}

- (void) awakeFromNib
{
    // Add an observer for the notification that a filter expression has been added
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(filterExpressionAdded:)
                                                 name:@"filterExpressionAdded" object:nil];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


// Delegate called before the Network settings preferences pane will be displayed
- (void)willBeDisplayed {
//    // Remove URL filter tab
//    [networkTabView removeTabViewItem:urlFilterTab];
    
    // Set URL filter expression parts if an expression is selected
    if ([filterArrayController selectedObjects].count) {
        NSString *currentlySelectedExpression = [filterArrayController valueForKeyPath:@"selection.expression"];
        [self setPartsForExpression:currentlySelectedExpression];
    }
    
    //Load settings password from user defaults
    //[self loadPrefs];
    //[chooseIdentity synchronizeTitleAndSelectedItem];
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    if (!self.SSLCertificatesNames)
    { //no certificates available yet, get them from keychain

        NSArray *SSLCertificatesInKeychain = [keychainManager getCertificatesOfType:certificateTypeSSL];
        self.SSLCertificates = [SSLCertificatesInKeychain valueForKeyPath:@"ref"];
        self.SSLCertificatesNames = [SSLCertificatesInKeychain valueForKeyPath:@"name"];
        [chooseCertificate removeAllItems];
        //first put "None" item in popupbutton list
        [chooseCertificate addItemWithTitle:NSLocalizedString(@"None", nil)];
        [chooseCertificate addItemsWithTitles: self.SSLCertificatesNames];
    }
    if (!self.caCertificatesNames)
    {
        NSArray *caCertificatesInKeychain = [keychainManager getCertificatesOfType:certificateTypeCA];
        self.caCertificates = [caCertificatesInKeychain valueForKeyPath:@"ref"];
        self.caCertificatesNames = [caCertificatesInKeychain valueForKeyPath:@"name"];
        [chooseCA removeAllItems];
        //first put "None" item in popupbutton list
        [chooseCA addItemWithTitle:NSLocalizedString(@"None", nil)];
        [chooseCA addItemsWithTitles: self.caCertificatesNames];
    }
    if (!self.certificates)
    {
        self.certificates = [keychainManager getCertificatesOfType:certificateTypeSSLDebug];
    }
    if (!self.identitiesNames)
    { //no identities available yet, get them from keychain
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


/// Filter Section

- (BOOL) URLFilterLearningMode {
    return [SEBURLFilter sharedSEBURLFilter].learningMode;
}

- (void) setURLFilterLearningMode:(BOOL)learningMode {
    [SEBURLFilter sharedSEBURLFilter].learningMode = learningMode;
}


// Action to set the enabled property of dependent buttons
// This is necessary because bindings don't work with private user defaults
- (IBAction) URLFilterEnableChanged:(NSButton *)sender {
    URLFilterEnableContentFilterButton.enabled = sender.state;
    URLFilterMessageControl.enabled = sender.state;
}


// Action to set the enableContentFilter property of the sharedSEBURLFilter
- (IBAction) URLFilterEnableContentFilterChanged:(NSButton *)sender {
    [SEBURLFilter sharedSEBURLFilter].enableContentFilter = sender.state;
}


- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    // Set URL filter expression parts if an expression is selected
    if ([filterArrayController selectedObjects].count) {
        NSString *currentlySelectedExpression = [filterArrayController valueForKeyPath:@"selection.expression"];
        [self setPartsForExpression:currentlySelectedExpression];
    }
}


- (IBAction) addExpression:(id)sender
{
    NSMutableData *newObject = [filterArrayController newObject];
    NSInteger selectedExpressionInTableView = [filterTableView selectedRow];
    [filterArrayController addObject:newObject];
    [filterArrayController setSelectionIndex:[[filterArrayController arrangedObjects] count]-1];

    NSInteger newSelectedExpressionInTableView = [filterTableView numberOfSelectedRows];
    DDLogDebug(@"Selected before: %ld, selected now: %ld", (long)selectedExpressionInTableView, (long)newSelectedExpressionInTableView);

}


- (IBAction)clearIgnoreList:(id)sender {
    // Ask user if the ignore list should really be cleared
    NSAlert *newAlert = [[NSAlert alloc] init];
    [newAlert setMessageText:NSLocalizedString(@"Clear Ignored URL List", nil)];
    [newAlert setInformativeText:NSLocalizedString(@"The list containing ignore filter expressions has only an effect on the 'Teach allowed/blocked URLs' mode; loading ignored URLs/resources won't display a dialog anymore. They are blocked anyways, because all not allowed URLs are blocked by the URL filter. Do you want to clear the list now?", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [newAlert addButtonWithTitle:NSLocalizedString(@"Clear", nil)];
    [newAlert setAlertStyle:NSInformationalAlertStyle];
    if ([newAlert runModal] == NSAlertSecondButtonReturn) {
        [[SEBURLFilter sharedSEBURLFilter] clearIgnoreRuleList];
    }
}


- (void)filterExpressionAdded:(NSNotification *)notification
{
    [filterArrayController addObject:[NSMutableDictionary dictionaryWithDictionary:notification.userInfo]];

}


// Filter expression field was changed
- (IBAction) selectedExpression:(NSTextField *)sender
{
    [self setPartsForExpression:sender.stringValue];
}


- (IBAction) regexChanged:(NSButton *)sender
{
    if (sender.state == YES) {
        // If regex is switched on, we clear all expression URL parts
        [self setPartsForExpression:nil];
    } else {
        [self setPartsForExpression:selectedExpression.stringValue];
    }
}

- (void) setPartsForExpression:(NSString *)expression
{
    SEBURLFilterExpression *expressionURL;
    BOOL selectionRegex = [[filterArrayController valueForKeyPath:@"selection.regex"] boolValue];
    if (selectionRegex == NO) {
        expressionURL = [SEBURLFilterExpression filterExpressionWithString:expression];
    }
    scheme.stringValue = expressionURL.scheme ? expressionURL.scheme : @"";
    user.stringValue = expressionURL.user ? expressionURL.user : @"";
    password.stringValue = expressionURL.password ? expressionURL.password : @"";
    host.stringValue = expressionURL.host ? expressionURL.host : @"";
//    port.stringValue = expressionURL.port ? expressionURL.port.stringValue : @"";
    self.expressionPort = expressionURL.port ? expressionURL.port.stringValue : @"";
    NSString *trimmedExpressionPath = [expressionURL.path stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
    path.stringValue = trimmedExpressionPath ? trimmedExpressionPath : @"";
    query.stringValue = expressionURL.query ? expressionURL.query : @"";
    fragment.stringValue = expressionURL.fragment ? expressionURL.fragment : @"";
    
    // Update filter rules
    [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
}


- (SEBURLFilterExpression *) getExpressionFromParts
{
    NSString *trimmedScheme = [scheme.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" :/"]];
    NSString *trimmedUser = [user.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /:@"]];
    NSString *trimmedPassword = [password.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /:@"]];
    NSString *trimmedHost = [host.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" :/@?#"]];
    NSString *trimmedPath = [path.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" :/?#"]];
    NSString *trimmedQuery = [query.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /?#"]];
    NSString *trimmedFragment = [fragment.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" /?#"]];
    
    return [[SEBURLFilterExpression alloc] initWithScheme:trimmedScheme user:trimmedUser password:trimmedPassword host:trimmedHost port:@([self.expressionPort intValue]) path:trimmedPath query:trimmedQuery fragment:trimmedFragment];
}


// Called when one of the filter expression parts was changed
- (IBAction) updateExpressionFromParts:(NSTextField *)sender
{
    SEBURLFilterExpression *filterExpression = [self getExpressionFromParts];
    NSString *filterExpressionString = [filterExpression string];
    
    // Set the expression in the text field
    if ([filterArrayController selectedObjects].count) {
        [filterArrayController setValue:filterExpressionString forKeyPath:@"selection.expression"];
    }

    // Update filter expression parts textfields (to take over proper formatting)
    [self setPartsForExpression:filterExpressionString];
    
    // Update filter rules
    [[SEBURLFilter sharedSEBURLFilter] updateFilterRules];
}



/// Certificates Section

// A certificate was selected in the drop down menu
- (IBAction) certificateSelected:(id)sender
{
    [self certificateSelected:sender type:certificateTypeSSL];
    
    [chooseCertificate selectItemAtIndex:0];
    [chooseCertificate synchronizeTitleAndSelectedItem];
}

- (void) certificateSelected:(id)sender type:(certificateTypes)certificateType
{
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSUInteger indexOfSelectedItem = [sender indexOfSelectedItem];
    if (indexOfSelectedItem) {
        SecCertificateRef certificate = (__bridge SecCertificateRef)([self.SSLCertificates objectAtIndex:indexOfSelectedItem-1]);
        NSData *certificateData = [keychainManager getDataForCertificate:certificate];
        
        NSMutableDictionary *certificateToEmbed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:certificateType], @"type",
                                            [sender titleOfSelectedItem], @"name",
                                            [certificateData base64EncodedStringWithOptions:0], @"certificateDataBase64",
                                            // We also save the certificate data into the deprecated subkey certificateDataWin
                                            // (for downwards compatibility to < SEB 2.2)
                                            [certificateData base64EncodedStringWithOptions:0], @"certificateDataWin",
                                            nil];
        [certificatesArrayController addObject:certificateToEmbed];
        
    }
}


// A CA (certificate authority) certificate was selected in the drop down menu
- (IBAction) CASelected:(id)sender
{
    NSUInteger indexOfSelectedItem = [sender indexOfSelectedItem];
    if (indexOfSelectedItem) {
        SecCertificateRef certificate = (__bridge SecCertificateRef)([self.caCertificates objectAtIndex:indexOfSelectedItem-1]);
        
        // Assume SSL type
        NSNumber *certType = [NSNumber numberWithInt:certificateTypeCA];
        
        NSData *certificateData = CFBridgingRelease(SecCertificateCopyData(certificate));
        
        if (certificateData)
        {
            mbedtls_x509_crt cert;
            mbedtls_x509_crt_init(&cert);
            
            if (mbedtls_x509_crt_parse_der(&cert, [certificateData bytes], [certificateData length]) == 0)
            {
                if (cert.ext_types & MBEDTLS_X509_EXT_BASIC_CONSTRAINTS)
                {
                    if (cert.ca_istrue)
                    {
                        certType = [NSNumber numberWithInteger:certificateTypeCA];
                    }
                }
                
                NSMutableDictionary *certificateToEmbed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    certType, @"type",
                                                    [sender titleOfSelectedItem], @"name",
                                                    [certificateData base64EncodedStringWithOptions:0], @"certificateDataBase64",
                                                    // We also save the certificate data into the deprecated subkey certificateDataWin
                                                    // (for downwards compatibility to < SEB 2.2)
                                                    [certificateData base64EncodedStringWithOptions:0], @"certificateDataWin",
                                                    nil];
                [certificatesArrayController addObject:certificateToEmbed];
                
            }
            
            mbedtls_x509_crt_free(&cert);
        }

        [chooseCA selectItemAtIndex:0];
        [chooseCA synchronizeTitleAndSelectedItem];
    }
}


// An identity was selected in the drop down menu
- (IBAction)identitySelected:(id)sender
{
    // Get certificate from selected identity
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSUInteger indexOfSelectedItem = [sender indexOfSelectedItem];
    if (indexOfSelectedItem) {
        SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:indexOfSelectedItem-1]);
        //SecCertificateRef certificate = [keychainManager getCertificateFromIdentity:identityRef];
        NSData *certificateData = [keychainManager getDataForIdentity:identityRef];
        
        NSMutableDictionary *identityToEmbed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:certificateTypeIdentity], @"type",
                                         [sender titleOfSelectedItem], @"name",
                                         certificateData, @"certificateData",
                                         nil];
        [certificatesArrayController addObject:identityToEmbed];
        
        [chooseIdentity selectItemAtIndex:0];
        [chooseIdentity synchronizeTitleAndSelectedItem];
    }
}


- (IBAction) showAdvancedCertificateSheet:(id)sender
{
    [NSApp beginSheet: advancedCertificatesSheet
       modalForWindow: [MBPreferencesController sharedController].window
        modalDelegate: nil
       didEndSelector: nil
          contextInfo: nil];
    [NSApp runModalForWindow: advancedCertificatesSheet];
    // Dialog is up here.
    [NSApp endSheet: advancedCertificatesSheet];
    [advancedCertificatesSheet orderOut: self];
}


- (BOOL) addingDebugCertificate
{
    certificateTypes embeddCertificateType = chooseEmbeddCertificateType.indexOfSelectedItem;
    return (embeddCertificateType == certificateTypeSSLDebug-1);
}

- (IBAction) embeddCertificateTypeChanged:(id)sender {
    BOOL showOverrideCommonName = self.addingDebugCertificate;
    overrideCommonName.hidden = !showOverrideCommonName;
    overrideCommonNameLabel.hidden = !showOverrideCommonName;
    // If the the certificate type "Debug Certificate" was selected
    if (showOverrideCommonName) {
        NSInteger selectedCertificateRow = advancedCertificatesList.selectedRow;
        if (selectedCertificateRow != -1) {
            NSString *certificateName = [advancedCertificatesArrayController valueForKeyPath:@"selection.name"];

            // Set the override common name to the default name of the selected cert
            overrideCommonName.stringValue = certificateName;
        }
    }
}

- (IBAction)advancedCertificateSelected:(id)sender {
    if (chooseEmbeddCertificateType.indexOfSelectedItem == certificateTypeSSLDebug-1) {
        // If the type of the certificate to embedd is "Debug Certificate"
        NSInteger selectedCertificateRow = advancedCertificatesList.selectedRow;
        if (selectedCertificateRow != -1) {
            NSString *certificateName = [advancedCertificatesArrayController valueForKeyPath:@"selection.name"];
            // Set the override common name to the default name of the selected cert
            overrideCommonName.stringValue = certificateName;
        }
    }
}


- (IBAction) cancelAdvancedCertificateSheet:(id)sender
{
    [NSApp stopModal];
}


- (IBAction) embeddAdvancedCertificate:(id)sender
{
    certificateTypes embeddCertificateType = chooseEmbeddCertificateType.indexOfSelectedItem;
    if (embeddCertificateType >= certificateTypeIdentity) {
        // Correct certificate type, as here identities are not offered
        embeddCertificateType++;
    }
    NSInteger selectedCertificateRow = advancedCertificatesList.selectedRow;
    if (selectedCertificateRow != -1) {
        NSDictionary *selectedCertificate = [advancedCertificatesArrayController selectedObjects][0];
        SecCertificateRef certificateRef = (__bridge SecCertificateRef)[selectedCertificate objectForKey:@"ref"];
        NSString *certificateName = [selectedCertificate objectForKey:@"name"];
        if (embeddCertificateType == certificateTypeSSLDebug) {
            if (overrideCommonName.stringValue.length > 0) {
                certificateName = overrideCommonName.stringValue;
            }
        }
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        NSData *certificateData = [keychainManager getDataForCertificate:certificateRef];
        if (certificateData) {
            NSMutableDictionary *certificateToEmbed;
            if (embeddCertificateType != certificateTypeSSLDebug) {
                // For a SSL/TLS and CA cert we also save its data into the deprecated subkey certificateDataWin
                // (for downwards compatibility to < SEB 2.2)
                // ToDo: Remove in SEB 2.3
                certificateToEmbed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithInt:embeddCertificateType], @"type",
                                                    certificateName, @"name",
                                                    [certificateData base64EncodedStringWithOptions:0], @"certificateDataBase64",
                                                    [certificateData base64EncodedStringWithOptions:0], @"certificateDataWin",
                                                    nil];
            } else {
                certificateToEmbed = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                    [NSNumber numberWithInt:embeddCertificateType], @"type",
                                                    certificateName, @"name",
                                                    [certificateData base64EncodedStringWithOptions:0], @"certificateDataBase64",
                                                    nil];
            }

            [certificatesArrayController addObject:certificateToEmbed];
        }
    }
    [NSApp stopModal];
}


/// Proxies Section

/*
 // Get Proxies directory
 NSDictionary *proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
 NSArray *proxies = (__bridge NSArray *)CFNetworkCopyProxiesForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://apple.com"], (__bridge CFDictionaryRef)proxySettings);
 NSDictionary *settings = [proxies objectAtIndex:0];
 DDLogDebug(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
 DDLogDebug(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
 DDLogDebug(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
 
 */


#pragma mark -
#pragma mark Proxy Types TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_proxyProtocols] count];
}

// Loads the enabled status for each proxy type from UserDefaults
// and selects/deselects the checkbox in the first column in the tableview for selecting the proxy type
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualTo:@"keyName"]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSDictionary *proxyDict = [[[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_proxyProtocols] objectAtIndex:row];
        NSString *key = [proxyDict objectForKey:@"keyName"];
        NSMutableDictionary *proxies = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_proxies"];
        id proxyEnabled = [proxies valueForKey:key];
        return proxyEnabled;
    }
    return 0;
    
    
}

// Sets/Resets the enabled status in UserDefaults for the proxy type which was selected/deselected
// with the according checkbox in the proxy type tableview
- (void)tableView:(NSTableView *)tableView setObjectValue:(id)value forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([[tableColumn identifier] isEqualTo:@"keyName"]) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        NSDictionary *proxyDict = [[[SEBUIUserDefaultsController sharedSEBUIUserDefaultsController] org_safeexambrowser_SEB_proxyProtocols] objectAtIndex:row];
        NSString *key = [proxyDict objectForKey:@"keyName"];
        NSMutableDictionary *proxies = [NSMutableDictionary dictionaryWithDictionary:[preferences secureObjectForKey:@"org_safeexambrowser_SEB_proxies"]];
        [proxies setObject:value forKey:key];
        [preferences setSecureObject:proxies forKey:@"org_safeexambrowser_SEB_proxies"];
    }
    [tableView reloadData];
}


// Saves the proxy exception list to settings
- (IBAction)saveProxyExceptionsList:(NSTextField *)sender
{
    NSString *exceptionsListString = sender.stringValue;
    NSArray *exceptionsList = [exceptionsListString componentsSeparatedByString:@","];
    NSMutableArray *parsedExceptionsList = [NSMutableArray new];
    for (NSString *exceptionHost in exceptionsList) {
        NSString *parsedExceptionHost = [exceptionHost stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (parsedExceptionHost.length > 0) {
            [parsedExceptionsList addObject:parsedExceptionHost];
        }
    }
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *proxies = [NSMutableDictionary dictionaryWithDictionary:[preferences secureObjectForKey:@"org_safeexambrowser_SEB_proxies"]];
    [proxies setObject:[parsedExceptionsList copy] forKey:@"ExceptionsList"];
    [preferences setSecureObject:proxies forKey:@"org_safeexambrowser_SEB_proxies"];
}

@end
