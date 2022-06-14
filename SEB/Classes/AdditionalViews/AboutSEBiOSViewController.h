//
//  AboutSEBiOSViewController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25/05/17.
//  Copyright (c) 2010-2017 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel, 
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre, 
//  Brigitte Schmucki, Oliver Rahs.
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
//  The Original Code is SafeExamBrowser for iOS.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2017 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <UIKit/UIKit.h>
#import "AboutSEBiOSViewController.h"
#import "SEBAboutController.h"
#import "SEBViewController.h"

#import <MessageUI/MessageUI.h>
//#import <CocoaLumberjack.h>
#import "DDFileLogger.h"


@class SEBViewController;


@interface AboutSEBiOSViewController : UIViewController <MFMailComposeViewControllerDelegate> {
    
    __weak IBOutlet UIScrollView *scrollView;
    __weak IBOutlet UILabel *copyrightLabel;
    __weak IBOutlet UILabel *appExtraShortName;
    __weak IBOutlet UILabel *appName;
    __weak IBOutlet UILabel *versionLabel;
    __weak IBOutlet UIButton *closeAbout;
    __weak IBOutlet UIButton *sendLogsButton;
    
    @private
    NSInteger attempts;
}

@property (nonatomic, strong) SEBViewController *sebViewController;

- (IBAction)sendLogsByEmail;


@end
