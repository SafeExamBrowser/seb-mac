//
//  SEBSystemManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 14.11.13.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBSystemManager.h"
#import "SEBCryptor.h"
#import "RNCryptor.h"
#include <SystemConfiguration/SystemConfiguration.h>

Boolean GetHTTPSProxySetting(char *host, size_t hostSize, UInt16 *port);

@implementation SEBSystemManager


- (NSString *) preventSC
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];

    /// Check if there is a redirected sc location persistently stored
    /// What only happends when it couldn't be reset last time SEB has run
    
    scTempPath = [self getStoredNewSCLocation];
    if (scTempPath.length > 0) {
        
        /// There is a redirected location saved
        DDLogWarn(@"There was a persistently saved redirected screencapture location (%@). Looks like SEB didn't quit properly when running last time.", scTempPath);
        
        // Delete the last directory
        if ([self removeTempDirectory:scTempPath]) {
            DDLogDebug(@"Removing persitantly saved redirected screencapture directory %@ worked.", scTempPath);
        }
        // Reset the redirected location
        [preferences setSecureString:@"" forKey:@"newDestination"];
        // Get the original location
        scLocation = [preferences secureStringForKey:@"currentDestination"];
        if (scLocation.length == 0) {
            // in case it wasn't saved properly, we reset to the OS X default sc location
            scLocation = [@"~/Desktop" stringByExpandingTildeInPath];
            DDLogWarn(@"The persistently saved original screencapture location wasn't found, it has been reset to the OS X default location %@", scLocation);
        }
    } else {
        
        /// No redirected location was persistently saved
        
        // Get current screencapture location
        scLocation = [self getCurrentSCLocation];
        DDLogDebug(@"Current screencapture location: %@", scLocation);
    }
    
    // Check if screenshots should be blocked in current settings
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
        
        /// Block screenshots
        
        // Store current (= original) location persistently
        [preferences setSecureString:scLocation forKey:@"currentDestination"];
        
        // Create a new random directory name
        NSData *randomData = [RNCryptor randomDataOfLength:kCCKeySizeAES256];
        unsigned char hashedChars[32];
        [randomData getBytes:hashedChars length:32];
        NSMutableString *randomHexString = [NSMutableString stringWithString:@"."];
        for (int i = 0 ; i < 32 ; ++i) {
            [randomHexString appendFormat: @"%02x", hashedChars[i]];
        }
        
        // Create the folder
        scTempPath = [randomHexString copy];
        NSString *scFullPath = [NSTemporaryDirectory() stringByAppendingPathComponent:randomHexString];
        BOOL isDir;
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:scFullPath isDirectory:&isDir]) {
            if(![fileManager createDirectoryAtPath:scFullPath withIntermediateDirectories:YES attributes:nil error:NULL]) {
                DDLogError(@"Error: Creating folder failed %@", scFullPath);
                // As a fallback just use the temp directory
                scFullPath = NSTemporaryDirectory();
            }
        }
        
        // Execute the redirect script
        if ([self executeSCAppleScript:scFullPath]) {
            DDLogDebug(@"sc redirect script didn't report an error");
        }
        
        // Get and verify the new location
        NSString *location = [self getCurrentSCLocation];
        if ([scFullPath isEqualToString:location]) {
            DDLogDebug(@"Changed sc location successfully to: %@", location);
        } else {
            DDLogDebug(@"Failed changing sc location, location is: %@", location);
            // If the sc location wasn't changed, we save an empty string to indicate this
            scTempPath = @"";
        }
        // Store scTempPath persistently
        [preferences setSecureString:scTempPath forKey:@"newDestination"];
        return location;
        
    } else {
        
        /// Blocking screenshots not active
        
        scLocation = nil;
        
        return scLocation;
    }
}


- (BOOL) restoreSC
{
    // Check if screenshots were blocked in the previously active settings
    if (scLocation.length > 0) {

        /// Unblock screenshots
        
        // Check if the saved path really exists
        BOOL isDir;
        NSFileManager *fileManager= [NSFileManager defaultManager];
        if(![fileManager fileExistsAtPath:scLocation isDirectory:&isDir]) {
            // No, the directory for storing screenshots doesn't exist
            // probably something went wrong sometimes ago (SEB crashed in a bad moment)
            // so restore the screen capture path to the OS X standard (user's desktop)
            scLocation = [@"~/Desktop" stringByExpandingTildeInPath];
        }
        
        // Restore original SC path
        if ([self executeSCAppleScript:scLocation]) {
            DDLogDebug(@"sc restore original value (%@) script didn't report an error", scLocation);
        }
        // Get and verify the new location
        NSString *location = [self getCurrentSCLocation];
        if ([scLocation isEqualToString:location]) {
            DDLogDebug(@"Restored sc location successfully to: %@", location);
        } else {
            DDLogDebug(@"Failed restoring sc location! Location is: %@", location);
        }
        // Remove temporary directory
        if ([self removeTempDirectory:scTempPath]) {
            NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
            [preferences setSecureString:@"" forKey:@"newDestination"];
            DDLogDebug(@"Removed redirected temp sc location %@ successfully.", scTempPath);
            return YES;
        } else {
            DDLogDebug(@"Failed removing redirected temp sc location %@", scTempPath);
            return NO;
        }
    }
    return YES;
}


- (void) adjustSC
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    
    /// Check if screenshots were blocked in the previously active settings

    if (scLocation.length > 0) {

        /// Yes, screenshots were blocked
        
        // Check if screenshots are allowed in current settings
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == YES) {
            // Yes, screenshots are no longer blocked: restore SC and switch to non-blocking
            [self restoreSC];
            [self preventSC];
        } // otherwise leave blocking active and don't do nothing

    } else {

        /// No, screenshots were not blocked
        
        // Check if screenshots are allowed in current settings
        if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_enablePrintScreen"] == NO) {
            // No, screenshots are blocked in new settings: activate blocking
            [self preventSC];
        } // otherwise leave blocking inactive and don't do nothing
    }
}


// Get current screencapture location
- (NSString *) getCurrentSCLocation
{
    // Get current screencapture location
    NSUserDefaults *appUserDefaults = [[NSUserDefaults alloc] init];
    [appUserDefaults addSuiteNamed:@"com.apple.screencapture"];
    NSDictionary *prefsDict = [appUserDefaults dictionaryRepresentation];
    return [prefsDict valueForKey:@"location"];
}


// Get stored redirected screencapture location
- (NSString *) getStoredNewSCLocation
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString *storedSCPath = [preferences secureStringForKey:@"newDestination"];
    // We perform this check for security reasons...
    if ([storedSCPath hasPrefix:@"../"]) {
        storedSCPath = nil;
    }
    return storedSCPath;
}


// Remove the temporary directory and return YES if successful
- (BOOL) removeTempDirectory:(NSString *)path
{
    if (path.length > 0) {
        NSString *fullTempPath = [NSTemporaryDirectory() stringByAppendingPathComponent:path];
        NSError *error = nil;
        
        // Read names of possible files contained in the temp sc directory
        NSArray *filesInTempDir = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:fullTempPath error:&error];
        DDLogDebug(@"Contents of the redirected sc directory: %@ or error when reading: %@", filesInTempDir, error.description);
        
        [[NSFileManager defaultManager] removeItemAtPath:fullTempPath error:&error];
        return error == nil;
    }
    return NO;
}


- (BOOL) executeSCAppleScript:(NSString *)location
{
    NSString *appleScriptSource = [NSString stringWithFormat:@"do shell script \"defaults write com.apple.screencapture location %@ && killall SystemUIServer\"", location];
    NSAppleScript* appleScript = [[NSAppleScript alloc] initWithSource:appleScriptSource];
    
    NSDictionary* errorDict;
    NSAppleEventDescriptor* returnDescriptor = NULL;
    returnDescriptor = [appleScript executeAndReturnError: &errorDict];
    return errorDict == nil;
}


Boolean GetHTTPSProxySetting(char *host, size_t hostSize, UInt16 *port)
// Returns the current HTTPS proxy settings as a C string
// (in the buffer specified by host and hostSize) and
// a port number.
{
    Boolean            result = 0;
    CFDictionaryRef    proxyDict;
    CFMutableDictionaryRef proxyDictSet;
    CFNumberRef        enableNum;
    int                enable;
    CFStringRef        hostStr;
    CFNumberRef        portNum = 0;
    int                portInt;
    SCDynamicStoreRef proxyStore;
    
    assert(host != NULL);
    assert(port != NULL);
    
    // Get the dictionary.
    
    printf("hostSize=%zu\n",hostSize);
    proxyStore =
    SCDynamicStoreCreate(NULL,CFSTR("NetScaler"),NULL,NULL);
    proxyDict = SCDynamicStoreCopyProxies(proxyStore);
    result = (proxyDict != NULL);
    
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    
    if (result) {
        enableNum = (CFNumberRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSEnable);
        
        result = (enableNum != NULL)
        && (CFGetTypeID(enableNum) ==
            CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(enableNum,
                                  kCFNumberIntType,
                                  &enable) && (enable != 0);
    }
    
    // Get the proxy host.  DNS names must be in ASCII.  If you
    // put a non-ASCII character  in the "Secure Web Proxy"
    // field in the Network preferences panel, the CFStringGetCString
    // function will fail and this function will return false.
    
    if (result) {
        hostStr = (CFStringRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSProxy);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) ==
            CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize,
                                    kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        portNum = (CFNumberRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSPort);
        
        result = (portNum != NULL)
        && (CFGetTypeID(portNum) ==
            CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum,
                                  kCFNumberIntType, &portInt);
    }
    if (result) {
        *port = (UInt16) portInt;
    }
    
    //proxyDictSet = SCDynamicStoreCopyProxies(NULL);
    proxyDictSet =
    CFDictionaryCreateMutableCopy(NULL,0,proxyDict);
    CFDictionarySetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSProxy,CFSTR("127.0.0.1"));
    enable = 1;
    CFDictionarySetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSEnable,CFNumberCreate(NULL,kCFNumberIntType,&enable));
    hostStr = (CFStringRef)
    CFDictionaryGetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSProxy);
    result = CFStringGetCString(hostStr, host,
                                (CFIndex) hostSize,
                                kCFStringEncodingASCII);
    printf("HTTPS-Set proxy host = %s\n",host);
    
    printf("now we try the new thing...\n");
    
    //if(SCDynamicStoreSetValue(NULL,kSCPropNetProxiesHTTPSProxy,CFSTR("127.0.0.1")))
    {
        
        if(SCDynamicStoreSetValue(proxyStore,kSCPropNetProxiesHTTPSProxy,proxyDictSet))
        {
            printf("store updated successfully...\n");
        }else {
            printf("store NOT updated successfully...\n");
            printf("Error is %s\n",SCErrorString(SCError()));
        }
        
        // Clean up.
        
        if (proxyDict != NULL) {
            CFRelease(proxyDict);
        }
        if ( ! result ) {
            *host = 0;
            *port = 0;
        }
        return result;
    }
}

- (BOOL) checkHTTPSProxySetting
{
    UInt16 port;
    char host[100];
    
    BOOL worked = GetHTTPSProxySetting(host,sizeof(host),&port);
    printf("HTTPS proxy host = %s\n",host);
    printf("HTTPS proxy port = %d\n",port);
    return worked;
}
//    int main(int argc, char** argv) {
//        UInt16 port;
//        char host[100];
//        
//        GetHTTPSProxySetting(host,sizeof(host),&port);
//        printf("HTTPS proxy host = %s\n",host);
//        printf("HTTPS proxy host = %d\n",port);
//    }

@end
