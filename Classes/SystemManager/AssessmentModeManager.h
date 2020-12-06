//
//  AssessmentModeManager.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 02.12.20.
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
- (BOOL) endAssessmentModeWithCallback:(id)callback
                              selector:(SEL)selector;

@property (weak) id <AssessmentModeDelegate> delegate;
@property(strong, nonatomic, nullable) AEAssessmentSession *assessmentSession API_AVAILABLE(macosx(10.15.4));

@end

NS_ASSUME_NONNULL_END
