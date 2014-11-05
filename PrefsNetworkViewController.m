//
//  PrefsNetworkViewController.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 12.02.13.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

// Preferences Network Pane
// Network/Internet settings like URL white/blacklists, certificates and proxy settings

#import "PrefsNetworkViewController.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBUIUserDefaultsController.h"
#import "SEBKeychainManager.h"

@implementation PrefsNetworkViewController

@synthesize groupRowTableColumn;

@synthesize certificatesNames;
@synthesize certificates;
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

// Delegate called before the Network settings preferences pane will be displayed
- (void)willBeDisplayed {
    // Remove URL filter tab
    [networkTabView removeTabViewItem:urlFilterTab];
    
    //Load settings password from user defaults
    //[self loadPrefs];
    //[chooseIdentity synchronizeTitleAndSelectedItem];
    if (!self.certificatesNames)
    { //no certificates available yet, get them from keychain
        SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
        NSArray *names;
        NSArray *certificatesInKeychain = [keychainManager getCertificatesAndNames:&names];
        self.certificates = certificatesInKeychain;
        self.certificatesNames = [names copy];
        [chooseCertificate removeAllItems];
        //first put "None" item in popupbutton list
        [chooseCertificate addItemWithTitle:NSLocalizedString(@"None", nil)];
        [chooseCertificate addItemsWithTitles: self.certificatesNames];
    }
    if (!self.identitiesNames)
    { //no identities available yet, get them from keychain
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



#pragma mark -
#pragma mark DropDownButton

// -------------------------------------------------------------------------------
//	dropDownAction:sender
//
//	User clicked the DropDownButton.
// -------------------------------------------------------------------------------
- (IBAction)dropDownAction:(id)sender
{
	// Drop down button clicked
}


- (IBAction)addRuleItem:(id)sender
{
    NSMenu *addRuleItemMenu = [[NSMenu alloc] initWithTitle:@""];
    [addRuleItemMenu insertItemWithTitle:NSLocalizedString(@"Add Rule",nil) action:@selector(addRule:) keyEquivalent:@"" atIndex:0];
    [addRuleItemMenu insertItemWithTitle:NSLocalizedString(@"Add Action to Rule",nil) action:@selector(addAction:) keyEquivalent:@"" atIndex:1];
}

- (void)addRule:(id)sender
{
    [treeController add:self];
}

- (void)addAction:(id)sender
{
    [treeController addChild:self];
}

#pragma mark -
#pragma mark Some NSOutlineView data source methods (rest is done using bindings to a NSTreeController)

// To get the "group row" look, we implement this method.
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if ([outlineView parentForItem:item]) {
        // If not nil; then the item has a parent.
        return NO;
    }
    return YES;
}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if (![outlineView parentForItem:item]) {
        [cell setFont:[NSFont fontWithName:@"Lucida Grande" size:12]];
    }
}

/*
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    if (tableColumn && ![outlineView parentForItem:item] && [[tableColumn identifier] isEqualToString:@"expression"]) {
        NSCell *descriptionTableColumn = [groupRowTableColumn dataCell];
        return descriptionTableColumn;
    }
    NSInteger row = [outlineView rowForItem:item];
    return [tableColumn dataCellForRow:row];
}

 // Get Proxies directory
 NSDictionary *proxySettings = (__bridge NSDictionary *)CFNetworkCopySystemProxySettings();
 NSArray *proxies = (__bridge NSArray *)CFNetworkCopyProxiesForURL((__bridge CFURLRef)[NSURL URLWithString:@"http://apple.com"], (__bridge CFDictionaryRef)proxySettings);
 NSDictionary *settings = [proxies objectAtIndex:0];
 NSLog(@"host=%@", [settings objectForKey:(NSString *)kCFProxyHostNameKey]);
 NSLog(@"port=%@", [settings objectForKey:(NSString *)kCFProxyPortNumberKey]);
 NSLog(@"type=%@", [settings objectForKey:(NSString *)kCFProxyTypeKey]);
 
 */


// Certificates Section

// A certificate was selected in the drop down menu
- (IBAction) certificateSelected:(id)sender
{
    //get certificate from selected identity
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSUInteger indexOfSelectedItem = [sender indexOfSelectedItem];
    if (indexOfSelectedItem) {
        SecCertificateRef certificate = (__bridge SecCertificateRef)([self.certificates objectAtIndex:indexOfSelectedItem-1]);
        NSData *certificateData = [keychainManager getDataForCertificate:certificate];
        
        NSDictionary *certificateToEmbed = [NSDictionary dictionaryWithObjectsAndKeys:
                                            [NSNumber numberWithInt:certificateTypeSSLClientCertificate], @"type",
                                            [sender titleOfSelectedItem], @"name",
                                            certificateData, @"certificateData",
                                            nil];
        [certificatesArrayController addObject:certificateToEmbed];
        
        [chooseCertificate selectItemAtIndex:0];
        [chooseCertificate synchronizeTitleAndSelectedItem];
    }
}

// An identity was selected in the drop down menu
- (IBAction)identitySelected:(id)sender
{
    //get certificate from selected identity
    SEBKeychainManager *keychainManager = [[SEBKeychainManager alloc] init];
    NSUInteger indexOfSelectedItem = [sender indexOfSelectedItem];
    if (indexOfSelectedItem) {
        SecIdentityRef identityRef = (__bridge SecIdentityRef)([self.identities objectAtIndex:indexOfSelectedItem-1]);
        //SecCertificateRef certificate = [keychainManager getCertificateFromIdentity:identityRef];
        NSData *certificateData = [keychainManager getDataForIdentity:identityRef];
        
        NSDictionary *identityToEmbed = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:certificateTypeIdentity], @"type",
                                         [sender titleOfSelectedItem], @"name",
                                         certificateData, @"certificateData",
                                         nil];
        [certificatesArrayController addObject:identityToEmbed];
        
        [chooseIdentity selectItemAtIndex:0];
        [chooseIdentity synchronizeTitleAndSelectedItem];
    }
}


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

@end
