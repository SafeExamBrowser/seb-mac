//
//  main.m
//  SEB
//
//  Created by Daniel R. Schneider on 29.04.10.
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


#import <Cocoa/Cocoa.h>
#import "NSWindow+SEBWindow.h"
#import "WebKit+WebKitExtensions.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {

//        NSBundle *webKit = [NSBundle bundleWithIdentifier:@"com.apple.WebKit"];
//        if (webKit.loaded) {
//            [webKit unload];
//        }
//        if (!webKit.loaded) {
//            [webKit load];
//        }

    // Swizzle NSWindow setLevel: Method
    [NSWindow setupChangingWindowLevels];
    [WebView setupOverridePlugins];

    //[NSUserDefaults setupPrivateUserDefaults];

    return NSApplicationMain(argc,  (const char **) argv);
    }
}
