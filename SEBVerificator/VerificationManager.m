//
//  VerficationManager.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 13.07.22.
//

#import "VerificationManager.h"
@import AppKit;

@implementation VerificationManager


- (NSArray *)associatedAppsForFile:(NSURL *)fileURL
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


- (NSArray *)associatedAppsForFileExtension:(NSString *)pathExtension
{
//    UTType;
//    [NSWorkspace.sharedWorkspace URLsForApplicationsToOpenContentType:pathExtension];
    
    CFArrayRef utisRef = UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension,(__bridge  CFStringRef) pathExtension,nil);
    NSLog( @"UTI: utisRef %@", utisRef);
    NSArray *utis = CFBridgingRelease(utisRef);
    NSMutableSet *mutableSet = [[NSMutableSet alloc] init];
    for (NSString *uti in utis) {
        CFArrayRef bundleIDsRef = LSCopyAllRoleHandlersForContentType((__bridge  CFStringRef) uti,kLSRolesEditor);
        [mutableSet addObjectsFromArray:CFBridgingRelease(bundleIDsRef)];
    }
    NSLog( @"bundleIDs: %@", mutableSet);
    return [mutableSet allObjects];
}


- (NSArray *)associatedAppsForURLScheme:(NSString *)scheme
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

//        if (status != noErr) {
//            // Public SHA1 fingerprint of the CA cert match string
//            reqStr = [NSString stringWithFormat:@"%@ %@ = %@%@%@",
//                      @"certificate",
//                      @"leaf",
//                      @"H\"013E2787748A74",
//                      @"103D62D2CDBF77",
//                      @"A1345517C482\""
//            ];
//
//            // create the requirement to check against
//            status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
//
//            if (status == noErr && req != NULL) {
//                status = SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req);
////                DDLogDebug(@"Returned from checking code signature of executable %@ with status %d", executablePath, (int)status);
//            }
//        }
        
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
