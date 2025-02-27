//
//  SEBEncapsulatedSettings.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 14.06.18.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "SEBEncapsulatedSettings.h"

@implementation SEBEncapsulatedSettings


- (SEBEncapsulatedSettings*)initWithCurrentSettings
{
    self = [super init];
    if (self) {
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        // Get current flag for private/local client settings
        self.userDefaultsPrivate = NSUserDefaults.userDefaultsPrivate;
        // Get current key/values from local or private UserDefaults
        self.settings = [preferences dictionaryRepresentationSEB];
        // Get current config URL
        self.configURL = [[MyGlobals sharedMyGlobals] currentConfigURL];
        // Get current Browser Exam Key
        self.browserExamKey = [preferences secureObjectForKey:@"org_safeexambrowser_currentData"];
        // Get current Config Key and its contained keys
        self.configKey = [preferences secureObjectForKey:@"org_safeexambrowser_configKey"];
        self.configKeyContainedKeys = [preferences secureObjectForKey:@"org_safeexambrowser_configKeyContainedKeys"];
    }
    return self;
}


- (void)restoreSettings
{
    // If config mode changed (private/local client settings), then switch to the mode active before
    if (self.userDefaultsPrivate != NSUserDefaults.userDefaultsPrivate) {
        [NSUserDefaults setUserDefaultsPrivate:self.userDefaultsPrivate];
    }
    // Restore all .seb (only the ones with prefix "org_safeexambrowser_SEB_"!) settings back into UserDefaults
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    [preferences storeSEBDictionary:self.settings];

    // Restore Browser Exam Key and Config Key back into UserDefaults
    [preferences setSecureObject:self.browserExamKey forKey:@"org_safeexambrowser_currentData"];
    [preferences setSecureObject:self.configKey forKey:@"org_safeexambrowser_configKey"];
    [preferences setSecureObject:self.configKeyContainedKeys forKey:@"org_safeexambrowser_configKeyContainedKeys"];
    
    // Set the original config file URL
    [[MyGlobals sharedMyGlobals] setCurrentConfigURL:self.configURL];
}


@end
