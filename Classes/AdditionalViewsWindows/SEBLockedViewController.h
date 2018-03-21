//
//  SEBLockedView.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 30/09/15.
//  Copyright (c) 2010-2018 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2018 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

/**
 * @protocol    SEBLockedViewControllerDelegate
 *
 * @brief       SEB locked view controllers confirming to the SEBLockedViewControllerDelegate
 *              protocol are setting an individual lock view and are controling parameters
 *              they provide.
 */
@protocol SEBLockedViewControllerDelegate <NSObject>
/**
 * @name        Item Attributes
 */
@required
/**
 * @brief       Delegate method to display an enter password dialog with the
 *              passed message text asynchronously, calling the callback
 *              method with the entered password when one was entered
 */
//- (void) showEnterUsernamePasswordDialog:(NSString *)text
//                                   title:(NSString *)title
//                                username:(NSString *)username
//                           modalDelegate:(id)modalDelegate
//                          didEndSelector:(SEL)didEndSelector;
/**
 * @brief       Delegate method to hide the previously displayed enter password dialog
 */
//- (void) hideEnterUsernamePasswordDialog;

@optional
/**
 * @brief       Delegate method to check for status of individual parameters
 *              and return an appropriate log string
 */
- (NSString *) logStringForParameters;

@end


#import <Cocoa/Cocoa.h>
#import "SEBController.h"
#import "SEBKeychainManager.h"

@class SEBController;

@interface SEBLockedViewController : NSViewController

@property (weak) id delegate;
@property (strong) SEBController *sebController;
@property (strong) SEBKeychainManager *keychainManager;
@property (readwrite, copy) NSAttributedString *resignActiveLogString;

- (void)setLockdownAlertMessage:(NSString *)newAlertMessage;
- (void)appendErrorString:(NSString *)errorString withTime:(NSDate *)errorTime;

@end
