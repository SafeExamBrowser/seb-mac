//
//  SEBBrowserController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 22/01/16.
//
//

#import "SEBBrowserController.h"

@implementation SEBBrowserController


/// Save the default user agent of the installed WebKit version
- (void) createSEBUserAgentFromDefaultAgent:(NSString *)defaultUserAgent
{
    // Get WebKit version number string to use it as Safari version
    NSRange webKitSubstring = [defaultUserAgent rangeOfString:@"AppleWebKit/"];
    NSString *webKitVersion;
    if (webKitSubstring.location != NSNotFound && (webKitSubstring.location + webKitSubstring.length) < defaultUserAgent.length) {
        webKitVersion = [defaultUserAgent substringFromIndex:webKitSubstring.location + webKitSubstring.length];
        webKitVersion = [[webKitVersion stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]  componentsSeparatedByString:@" "][0];
    } else {
        webKitVersion = SEBUserAgentDefaultSafariVersion;
    }
    
    // Check if default user agent string contains the browser "Version" number string
    NSString *versionString = @"";
    if ([defaultUserAgent rangeOfString:@"Version/"].location == NSNotFound) {
        versionString = @"Version/10.0 ";
    }

    defaultUserAgent = [defaultUserAgent stringByAppendingString:[NSString stringWithFormat:@" %@%@/%@", versionString, SEBUserAgentDefaultBrowserSuffix, webKitVersion]];
    [[MyGlobals sharedMyGlobals] setValue:defaultUserAgent forKey:@"defaultUserAgent"];
}


- (NSString *) backToStartURLString
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    NSString* backToStartURL;
    if ([preferences secureBoolForKey:@"org_safeexambrowser_SEB_restartExamUseStartURL"]) {
        // Load start URL from the system's user defaults
        backToStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_startURL"];
        DDLogInfo(@"Will load Start URL in main browser window: %@", backToStartURL);
    } else {
        backToStartURL = [preferences secureStringForKey:@"org_safeexambrowser_SEB_restartExamURL"];
        DDLogInfo(@"Will load Back to Start URL in main browser window: %@", backToStartURL);
    }
    return backToStartURL;
}

@end
