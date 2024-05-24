//
//  SEBUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 07.11.11.
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

#import "SEBUIUserDefaultsController.h"


@implementation SEBUIUserDefaultsController

static SEBUIUserDefaultsController *sharedSEBUIUserDefaultsController = nil;

//@synthesize org_safeexambrowser_SEB_cryptoIdentities = _org_safeexambrowser_SEB_cryptoIdentities;


+ (SEBUIUserDefaultsController *)sharedSEBUIUserDefaultsController
{
	@synchronized(self)
	{
		if (sharedSEBUIUserDefaultsController == nil)
		{
			sharedSEBUIUserDefaultsController = [[self alloc] init];
		}
	}
    
	return sharedSEBUIUserDefaultsController;
}


- (NSArray *) org_safeexambrowser_SEB_shareConfigFormats {
    return [NSArray arrayWithObjects:
            [NSString stringWithFormat:@"%@ %@", SEBShortAppName, NSLocalizedString(@"File", @"")],
            NSLocalizedString(@"Config URL", @""),
            NSLocalizedString(@"QR Code", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByLinkPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"get generally blocked", @""), NSLocalizedString(@"open in same window", @""), NSLocalizedString(@"open in new window", @""), nil];
}

- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByScriptPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"get generally blocked", @""), NSLocalizedString(@"open in same window", @""), NSLocalizedString(@"open in new window", @""), nil];
}


- (NSArray *) org_safeexambrowser_SEB_browserWindowWebViewPolicies {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Automatic", @""),
            NSLocalizedString(@"Force Classic", @""),
            NSLocalizedString(@"Prefer Modern in New Tab+Different Host", @""),
            NSLocalizedString(@"Prefer Modern", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_browserUserAgentEnvironments {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Standard user agent", @""),
            NSLocalizedString(@"Win: User agent for desktop mode", @""),
            NSLocalizedString(@"Win: User agent for touch/tablet mode", @""),
            NSLocalizedString(@"iOS User agent", @""), nil];
}


- (NSArray *) org_safeexambrowser_SEB_chooseFileToUploadPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"manually with file requester", @""), NSLocalizedString(@"by attempting to upload same file downloaded before", @""), NSLocalizedString(@"by only allowing to upload the same file downloaded before", @""), nil];
}


- (NSArray *) org_safeexambrowser_SEB_certificateTypes {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"SSL Certificate", @""),
            NSLocalizedString(@"Identity", @""),
            NSLocalizedString(@"CA Certificate", @""),
            NSLocalizedString(@"Debug Certificate", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_SSLCertificateTypes {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"SSL Certificate", @""),
            NSLocalizedString(@"CA Certificate", @""),
            NSLocalizedString(@"Debug Certificate", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_cryptoIdentities {
    return [NSArray arrayWithObjects:NSLocalizedString(@"Fetching identities", @""), nil];
}


- (NSArray *) org_safeexambrowser_SEB_browserWindowPositionings {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Left", @""),
            NSLocalizedString(@"Center", @""),
            NSLocalizedString(@"Right", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_browserWindowShowURLPolicies {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Never", @""),
            NSLocalizedString(@"Only on load error", @""),
            NSLocalizedString(@"Before receiving title", @""),
            NSLocalizedString(@"Always", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_proxyProtocols {
    return [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"proxyAutoDiscoveryEnable",
             @"keyName",
             NSLocalizedString(@"Auto Proxy Discovery", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"proxyAutoConfigEnable",
             @"keyName",
             NSLocalizedString(@"Automatic Proxy Configuration", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"HTTPEnable",
             @"keyName",
             NSLocalizedString(@"Web Proxy (HTTP)", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"HTTPSEnable",
             @"keyName",
             NSLocalizedString(@"Secure Web Proxy (HTTPS)", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"FTPEnable",
             @"keyName",
             NSLocalizedString(@"FTP Proxy", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"SOCKSEnable",
             @"keyName",
             NSLocalizedString(@"SOCKS Proxy", @""),
             @"name",
             nil],
            [NSDictionary dictionaryWithObjectsAndKeys:
             @"RTSPEnable",
             @"keyName",
             NSLocalizedString(@"Streaming Proxy (RTSP)", @""),
             @"name",
             nil],
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_sebServicePolicies {
    return [NSArray arrayWithObjects:
            [NSString stringWithFormat:NSLocalizedString(@"allow to use %@ without service", @""), SEBShortAppName],
            NSLocalizedString(@"warn when service is not running", @""),
             [NSString stringWithFormat:NSLocalizedString(@"allow to use %@ only with service", @""), SEBShortAppName],
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_URLFilterRuleActions {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"block", @""),
            NSLocalizedString(@"allow", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_logLevels {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"Error", @""),
            NSLocalizedString(@"Warning", @""),
            NSLocalizedString(@"Info", @""),
            NSLocalizedString(@"Debug", @""),
            NSLocalizedString(@"Verbose", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_minMacOSVersions {
    return [NSArray arrayWithObjects:
            [NSString stringWithFormat:NSLocalizedString(@"10.7 (this %@: 10.13)", @""), SEBShortAppName],
            [NSString stringWithFormat:NSLocalizedString(@"10.8 (this %@: 10.13)", @""), SEBShortAppName],
            [NSString stringWithFormat:NSLocalizedString(@"10.9 (this %@: 10.13)", @""), SEBShortAppName],
            [NSString stringWithFormat:NSLocalizedString(@"10.10 (this %@: 10.13)", @""), SEBShortAppName],
            [NSString stringWithFormat:NSLocalizedString(@"10.11 (this %@: 10.13)", @""), SEBShortAppName],
            [NSString stringWithFormat:NSLocalizedString(@"10.12 (this %@: 10.13)", @""), SEBShortAppName],
            NSLocalizedString(@"10.13 High Sierra", @""),
            NSLocalizedString(@"10.14 Mojave", @""),
            NSLocalizedString(@"10.15 Catalina", @""),
            NSLocalizedString(@"11 Big Sur", @""),
            NSLocalizedString(@"12 Monterey", @""),
            NSLocalizedString(@"13 Ventura", @""),
            NSLocalizedString(@"14 Sonoma", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_operatingSystems {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"macOS", @""),
            NSLocalizedString(@"Win", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_allowiOSBetaVersions {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"None", @""),
            NSLocalizedString(@"iOS 17", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_mobileStatusBarAppearances {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"None", @""),
            NSLocalizedString(@"White on Black", @""),
            NSLocalizedString(@"Black on White", @""),
            nil];
}


- (NSArray *) org_safeexambrowser_SEB_mobileStatusBarAppearancesExtended {
    return [NSArray arrayWithObjects:
            NSLocalizedString(@"None", @""),
            NSLocalizedString(@"White on Black", @""),
            NSLocalizedString(@"Black on White", @""),
            NSLocalizedString(@"None - Black", @""),
            NSLocalizedString(@"None - White", @""),
            nil];
}


@end
