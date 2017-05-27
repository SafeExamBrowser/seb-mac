//
//  SEBAboutController.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 26.05.17.
//
//

#import "SEBAboutController.h"

@implementation SEBAboutController

- (NSString *) version
{
    // Get application short version and bundle (build) version string
    NSString* versionString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleShortVersionString"];
    NSString* buildNumber = [[MyGlobals sharedMyGlobals] infoValueForKey:@"CFBundleVersion"];
    versionString = [NSString stringWithFormat:@"%@ %@ (%@)", NSLocalizedString(@"Version",nil), versionString, buildNumber];

    return versionString;
}


- (NSString *) copyright
{
    NSString* copyrightString = [[MyGlobals sharedMyGlobals] infoValueForKey:@"NSHumanReadableCopyright"];
    copyrightString = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@",
                       copyrightString,
                       NSLocalizedString(@"This project was partly carried out under the program 'AAA/SWITCH – e-Infrastructure for e-Science' lead by SWITCH, the Swiss National Research and Education Network and the cooperative CRUS project 'Learning Infrastructure' coordinated by SWITCH, supported by funds from the ETH Board.", nil),
                       NSLocalizedString(@"Project concept: Thomas Piendl, Daniel R. Schneider, Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, Brigitte Schmucki, Oliver Rahs.", nil),
                       NSLocalizedString(@"Code contributions © 2015 - 2016 Janison", nil)];

    return copyrightString;
}

@end
