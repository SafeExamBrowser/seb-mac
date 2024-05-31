//
//  AssessmentModeManager.h
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

@import Foundation;
@import AutomaticAssessmentConfiguration;

NS_ASSUME_NONNULL_BEGIN

@protocol AssessmentModeDelegate <NSObject>

- (void) assessmentSessionWillBegin;

- (void) assessmentSessionDidBeginWithCallback:(id)callback
                                      selector:(SEL)selector;
- (void) assessmentSessionFailedToBeginWithError:(NSError *)error
                                        callback:(id)callback
                                        selector:(SEL)selector;
- (void) assessmentSessionWillEnd;

- (void) assessmentSessionDidEndWithCallback:(id)callback
                                    selector:(SEL)selector;
- (void) assessmentSessionWasInterruptedWithError:(NSError *)error;

@end


API_AVAILABLE(macos(10.15.4))
@interface AssessmentModeManager: NSObject <AEAssessmentSessionDelegate> {
    @private
    id successCallback;
    SEL successSelector;
}

- (instancetype)initWithCallback:(id)callback
                        selector:(SEL)selector;
- (BOOL) beginAssessmentMode;
- (BOOL) beginAssessmentModeWithConfiguration:(AEAssessmentConfiguration*)config;
- (BOOL) endAssessmentModeWithCallback:(id)callback
                              selector:(SEL)selector;

@property (weak) id <AssessmentModeDelegate> delegate;
@property(strong, nonatomic, nullable) AEAssessmentSession *assessmentSession API_AVAILABLE(macosx(10.15.4));

@end

NS_ASSUME_NONNULL_END
