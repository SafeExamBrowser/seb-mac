//
//  SEBCryptor.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 24.01.13.
//  Copyright (c) 2010-2013 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
//  Dirk Bauer, Karsten Burger, Marco Lehre,
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
//  (c) 2010-2013 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBCryptor.h"
#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "SEBEncryptedUserDefaultsController.h"
#import "RNCryptor.h"
#import "RNEncryptor.h"
#import "RNDecryptor.h"
#import "Constants.h"

@implementation SEBCryptor

//@synthesize HMACKey = _HMACKey;

static SEBCryptor *sharedSEBCryptor = nil;

+ (SEBCryptor *)sharedSEBCryptor
{
	@synchronized(self)
	{
		if (sharedSEBCryptor == nil)
		{
			sharedSEBCryptor = [[self alloc] init];
		}
	}
    
	return sharedSEBCryptor;
}


// Method called when a value is written into the UserDefaults
// Calculates a checksum hash to 
- (void)updateEncryptedUserDefaults
{
    // Copy preferences to a dictionary
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSDictionary *prefsDict = [preferences getSEBUserDefaultsDomains];
        
    // Filter dictionary so only org_safeexambrowser_SEB_ keys are included
    NSSet *filteredPrefsSet = [prefsDict keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop)
                               {
                                   if ([key hasPrefix:@"org_safeexambrowser_SEB_"])
                                       return YES;
                                   
                                   else return NO;
                               }];
    NSMutableDictionary *filteredPrefsDict = [NSMutableDictionary dictionaryWithCapacity:[filteredPrefsSet count]];

    // get default settings
    NSDictionary *defaultSettings = [preferences sebDefaultSettings];
    
    // iterate keys and read all values
    for (NSString *key in filteredPrefsSet) {
        id value = [preferences secureObjectForKey:key];
        id defaultValue = [defaultSettings objectForKey:key];
        Class valueClass = [value superclass];
        Class defaultValueClass = [defaultValue superclass];
        if (valueClass && defaultValueClass && !([defaultValue isKindOfClass:valueClass] || [value isKindOfClass:defaultValueClass])) {
            // Class of local preferences value is different than the one from the default value
            // If yes, then cancel reading .seb file and create error object
            [self presentPreferencesCorruptedError];
            return;
        }
        if (value) [filteredPrefsDict setObject:value forKey:key];
    }
	NSMutableData *archivedPrefs = [[NSKeyedArchiver archivedDataWithRootObject:filteredPrefsDict] mutableCopy];

    // Get salt for exam key
    NSData *HMACKey = [preferences secureDataForKey:@"org_safeexambrowser_SEB_examKeySalt"];
    if ([HMACKey isEqualToData:[NSData data]]) {
        [self generateExamKeySalt];
#ifdef DEBUG
        NSLog(@"Generated new exam key salt");
#endif
    }

    NSMutableData *HMACData = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA256, HMACKey.bytes, HMACKey.length, archivedPrefs.mutableBytes, archivedPrefs.length, [HMACData mutableBytes]);
    [preferences setValue:HMACData forKey:@"currentData"];
}


// Calculate a random salt value for the Browser Exam Key and save it to UserDefaults
- (void)generateExamKeySalt
{
	NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSData *HMACKey = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
    [preferences setSecureObject:HMACKey forKey:@"org_safeexambrowser_SEB_examKeySalt"];
}


- (void)presentPreferencesCorruptedError
{
    NSDictionary *newDict = @{ NSLocalizedDescriptionKey :
                                   NSLocalizedString(@"Local SEB settings are corrupted!", nil),
                               /*NSLocalizedFailureReasonErrorKey :
                                NSLocalizedString(@"Either an incompatible version of SEB has been used on this computer or the preferences file has been manipulated. In the first case you can quit SEB now and use the previous version to export settings as a .seb config file for reconfiguring the new version. Otherwise local settings need to be reset to the default values in order for SEB to continue running.", nil),*/
                               //NSURLErrorKey : furl,
                               NSRecoveryAttempterErrorKey : self,
                               NSLocalizedRecoverySuggestionErrorKey :
                                   NSLocalizedString(@"The preferences file has either been manipulated or created by an incompatible SEB version. You can reset settings now or quit and try to use your previous SEB version to export settings as a .seb file for configuring the new version.\n\nReset local settings and continue?", @""),
                               NSLocalizedRecoveryOptionsErrorKey :
                                   @[NSLocalizedString(@"Continue", @""), NSLocalizedString(@"Quit", @"")] };
    
    NSError *newError = [[NSError alloc] initWithDomain:sebErrorDomain
                                                   code:1 userInfo:newDict];
    [NSApp presentError:newError];
}


// Error recovery attempter when local preferences need to be reset
- (BOOL)attemptRecoveryFromError:(NSError *)error
                     optionIndex:(unsigned int)recoveryOptionIndex
{
    
    BOOL success = NO;
    
    if (recoveryOptionIndex == 0) { // Recovery requested.
        [[NSUserDefaults standardUserDefaults] resetSEBUserDefaults];
        [self updateEncryptedUserDefaults];
        success = YES;
    }
    if (recoveryOptionIndex == 1) { // Quit requested.
        // Terminate SEB without any further user confirmation required
        [[NSNotificationCenter defaultCenter]
         postNotificationName:@"requestQuitNotification" object:self];
        success = NO;
    }
    return success;
}


@end
