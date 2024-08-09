//
//  AssessmentModeManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 02.12.20.
//  Copyright (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#ifdef __MAC_10_15_4

#import "AssessmentModeManager.h"

@implementation AssessmentModeManager

- (instancetype)initWithCallback:(id)callback
                        selector:(SEL)selector
                        fallback:(BOOL)fallback
{
    self = [super init];
    if (self) {
        successCallback = callback;
        successSelector = selector;
        successFallback = fallback;
    }
    return self;
}

- (BOOL) beginAssessmentMode
{
    AEAssessmentConfiguration *config = [AEAssessmentConfiguration new];
    return [self beginAssessmentModeWithConfiguration:config];
}

- (BOOL) beginAssessmentModeWithConfiguration:(AEAssessmentConfiguration*)config
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (self.assessmentSession && self.assessmentSession.active) {
        DDLogWarn(@"Assessment session is already active!");
        return NO;
    }
    AEAssessmentSession *session = [[AEAssessmentSession alloc] initWithConfiguration:config];
    session.delegate = self;
    self.assessmentSession = session;
    [self.delegate assessmentSessionWillBegin];
    
    [session begin];
    return YES;
}

- (BOOL) endAssessmentModeWithCallback:(id)callback
                              selector:(SEL)selector
              quittingToAssessmentMode:(BOOL)quittingToAssessmentMode
{
    DDLogDebug(@"%s callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));

    if (self.assessmentSession && self.assessmentSession.active) {
        successCallback = callback;
        successSelector = selector;
        successQuittingToAssessmentMode = quittingToAssessmentMode;
        DDLogDebug(@"%s: Ending assessment session, set callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
        [self.delegate assessmentSessionWillEnd];

        [self.assessmentSession end];
        return YES;
    } else {
        DDLogWarn(@"Assessment session is not active!");
        [self.delegate assessmentSessionWillEnd];
        [self.delegate assessmentSessionDidEndWithCallback:callback selector:selector quittingToAssessmentMode:quittingToAssessmentMode];
        return NO;
    }
}


- (void) assessmentSessionDidBegin:(AEAssessmentSession *)session
{
    DDLogDebug(@"%s", __FUNCTION__);
    [self.delegate assessmentSessionDidBeginWithCallback:successCallback selector:successSelector fallback:successFallback];
}

- (void) assessmentSession:(AEAssessmentSession *)session failedToBeginWithError:(NSError *)error
{
    DDLogDebug(@"%s error: %@", __FUNCTION__, error);
    self.assessmentSession = nil;
    [self.delegate assessmentSessionFailedToBeginWithError:error callback:successCallback selector:successSelector fallback:successFallback];
}

- (void) assessmentSessionDidEnd:(AEAssessmentSession *)session
{
    DDLogDebug(@"%s: Will call delegate assessmentSessionDidEndWithCallback: %@ selector: %@", __FUNCTION__, successCallback, NSStringFromSelector(successSelector));
    self.assessmentSession = nil;
    if (successCallback) {
        id callback = successCallback;
        successCallback = nil;
        DDLogDebug(@"%s: Reset callback for delegate assessmentSessionDidEndWithCallback:selector: to %@", __FUNCTION__, successCallback);
        [self.delegate assessmentSessionDidEndWithCallback:callback selector:successSelector quittingToAssessmentMode:successQuittingToAssessmentMode];
    }
}

- (void) assessmentSession:(AEAssessmentSession *)session wasInterruptedWithError:(NSError *)error
{
    DDLogDebug(@"%s error: %@", __FUNCTION__, error);
    [self.delegate assessmentSessionWasInterruptedWithError:error];
    [session end];
}


@end
#endif
