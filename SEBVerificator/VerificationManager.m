//
//  VerficationManager.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 13.07.22.
//  Copyright (c) 2010-2023 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Marco Lehre, Tobias Halbherr, Dirk Bauer, Kai Reuter,
//  Karsten Burger, Brigitte Schmucki, Oliver Rahs.
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
//  (c) 2010-2023 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import "VerificationManager.h"
@import AppKit;
#import "UniformTypeIdentifiers/UTType.h"
#import "UniformTypeIdentifiers/UTCoreTypes.h"

@implementation VerificationManager


- (NSArray<NSString *> *)associatedAppsForFile:(NSURL *)fileURL
{
    // Ask launch services for the different apps that it thinks could edit this file.
    // This is usually a more useful list than what can view the file.
    LSRolesMask roles = kLSRolesEditor;
    CFArrayRef urls = LSCopyApplicationURLsForURL((__bridge CFURLRef)fileURL, roles);
    NSArray *appUrls = CFBridgingRelease(urls);

    // Extract the app names and sort them for prettiness.
    NSMutableArray *appNames = [NSMutableArray arrayWithCapacity: appUrls.count];

    for (NSURL *url in appUrls) {
        [appNames addObject: url.lastPathComponent];
    }
    [appNames sortUsingSelector: @selector(compare:)];

    // Finally emit to the user.
    for (NSString *appName in appNames) {
        printf ("%s\n", appName.UTF8String);
    }
    return appNames.copy;
}


- (NSArray<NSString *> *)associatedAppsForFileExtension:(NSString *)pathExtension
{
    CFArrayRef utisRef = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension,(__bridge  CFStringRef) pathExtension,nil);
    NSLog( @"UTI: utisRef %@", utisRef);
    NSArray *utis = CFBridgingRelease(utisRef);
    NSMutableSet *mutableSet = [[NSMutableSet alloc] init];
    for (NSString *uti in utis) {
        CFArrayRef bundleIDsRef = LSCopyAllRoleHandlersForContentType((__bridge  CFStringRef) uti, kLSRolesAll);
        [mutableSet addObjectsFromArray:CFBridgingRelease(bundleIDsRef)];
    }
    NSLog( @"bundleIDs: %@", mutableSet);
    return [mutableSet allObjects];
}


- (nullable NSURL *)defaultAppForFileExtension:(NSString *)pathExtension
{
    NSURL *appURL;
    if (@available(macOS 12.0, *)) {
        UTType *uti = [UTType typeWithTag:pathExtension
                                 tagClass:UTTagClassFilenameExtension
                         conformingToType:UTTypeData];
        appURL = [NSWorkspace.sharedWorkspace URLForApplicationToOpenContentType:uti];
    } else {
        NSArray *utis = CFBridgingRelease(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension,(__bridge  CFStringRef) pathExtension,nil));
        NSLog( @"UTIs: %@", utis);
        for (NSString *uti in utis) {
            NSURL *appURLForUTI = CFBridgingRelease(LSCopyDefaultApplicationURLForContentType((__bridge  CFStringRef) uti, kLSRolesAll, NULL));
            if (!appURL) {
                appURL = appURLForUTI;
            } else if (![appURL isEqualTo:appURLForUTI]) {
                appURL = nil;
                break;
            }
        }
    }
    return appURL;
}


- (nullable NSURL *)defaultAppForURLScheme:(NSString *)urlScheme
{
    NSURL *appURL;
//    if (@available(macOS 12.0, *)) {
//        UTType *uti = [UTType typeWithTag:urlScheme
//                                 tagClass:UTTagClassMIMEType
//                         conformingToType:UTTypeData];
//        appURL = [NSWorkspace.sharedWorkspace URLForApplicationToOpenContentType:uti];
//    } else {
    NSString *bundleID = CFBridgingRelease(LSCopyDefaultHandlerForURLScheme((__bridge  CFStringRef) urlScheme));
        if (bundleID) {
            appURL = [NSWorkspace.sharedWorkspace URLForApplicationWithBundleIdentifier: bundleID];
        }
//    }
    return appURL;
}


- (NSArray<NSString *> *)associatedAppsForURLScheme:(NSString *)scheme
{
    CFArrayRef schemeHandlersRef = LSCopyAllHandlersForURLScheme((__bridge  CFStringRef) scheme);
    return CFBridgingRelease(schemeHandlersRef);
}


- (BOOL)signedSEBExecutable:(NSString *)executablePath
{
    if (executablePath) {
        NSURL * executableURL = [NSURL fileURLWithPath:executablePath isDirectory:NO];

//        DDLogDebug(@"Evaluating code signature of %@", executablePath);
        
        OSStatus status;
        SecStaticCodeRef ref = NULL;
        
        // obtain the cert info from the executable
        status = SecStaticCodeCreateWithPath((__bridge CFURLRef)executableURL, kSecCSDefaultFlags, &ref);
        
        if (ref == NULL) {
//            DDLogDebug(@"Couldn't obtain certificate info from executable %@", executablePath);
            return NO;
        }
        if (status != noErr) {
//            DDLogDebug(@"Couldn't obtain certificate info from executable %@", executablePath);
            return NO;
        }
        
        SecRequirementRef req = NULL;
        NSString * reqStr;
        
        // Public SHA1 fingerprint of the CA certificate
        // for macOS system software signed by Apple this is the
        // "Software Signing" certificate (use Max Inspect from App Store or similar)
        reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                  @"certificate",
                  @"leaf",
                  @"H\"B33FF6079EE4E3",
                  @"8BEF3BFF8AA4DC",
                  @"4F7CD5C2250F\""
                  ];
        // create the requirement to check against
        status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
        
        if (status == noErr && req != NULL) {
            status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
//            DDLogDebug(@"Returned from checking code signature of executable %@ with status %d", executablePath, (int)status);
        }

        if (status != noErr) {
            // Public SHA1 fingerprint of the CA cert match string
            reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
                      @"certificate",
                      @"leaf",
                      @"H\"70E916BF7D906D",
                      @"0AEE89AEAD1406",
                      @"6DB3E45E511A\""
            ];

            // create the requirement to check against
            status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);

            if (status == noErr && req != NULL) {
                status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
////                DDLogDebug(@"Returned from checking code signature of executable %@ with status %d", executablePath, (int)status);
            }
        }
        
        if (ref) {
            CFRelease(ref);
        }
        if (req) {
            CFRelease(req);
        }
            
        if (status != noErr) {
//            DDLogDebug(@"Code signature suggests that %@ isn't correctly signed macOS system software.", executablePath);
            return NO;
        }

//        DDLogDebug(@"Code signature of %@ was checked and it positively identifies macOS system software.", executablePath);
        
        return YES;
    } else {
//        DDLogDebug(@"Couldn't determine executable path of process with PID %d.", runningExecutablePID);
        return NO;
    }
}

@end
