//
//  WebKit+WebKitExtensions.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 08.12.11.
//  Copyright (c) 2010-2019 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2019 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "WebKit+WebKitExtensions.h"
#import "MethodSwizzling.h"


@implementation WebPreferences (WebPreferencesKVCSupport)

- (BOOL)isPlugInsEnabled
{
    return [self arePlugInsEnabled];
}

@end


@implementation WebView (WebViewKVCSupport)

- (BOOL)maintainsBackForwardList
{
    if ([self backForwardList]) {
        return YES;
    } else {
        return NO;
    }
}

@end


@implementation WebView (WebViewOverrideSetPlugin)

+ (void)setupOverridePlugins
{
    SEL selector = NSSelectorFromString(@"_registerPluginMIMEType:");
    [self swizzleClassMethod:selector
             withMethod:@selector(_newRegisterPluginMIMEType:)];
}


// Override the WebView method _registerPluginMIMEType:(NSString *)MIMEType
// to prevent the Acrobat Reader plug-in to be registered for the MIME type
// "application/pdf", which overrides the internal WebKit PDF viewer
+ (void)_newRegisterPluginMIMEType:(NSString *)MIMEType
{
    NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
    if ([MIMEType isEqualToString:@"application/pdf"] && ![preferences secureBoolForKey:@"org_safeexambrowser_SEB_allowPDFPlugIn"])
    {
        return;
    }
    else
    {
        [WebView _newRegisterPluginMIMEType:MIMEType];
    }
}


@end
