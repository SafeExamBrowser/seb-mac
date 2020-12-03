//
//  AssessmentModeManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 02.12.20.
//

#ifdef __MAC_10_15_4

#import "AssessmentModeManager.h"

@implementation AssessmentModeManager

- (instancetype)initWithCallback:(id)callback
                        selector:(SEL)selector
{
    self = [super init];
    if (self) {
        successCallback = callback;
        successSelector = selector;
    }
    return self;
}

- (void) beginAssessmentMode
{
    if (@available(macOS 10.15.4, *)) {
        AEAssessmentConfiguration *config = [AEAssessmentConfiguration new];
        AEAssessmentSession *session = [[AEAssessmentSession alloc] initWithConfiguration:config];
        session.delegate = self;
        self.assessmentSession = session;
        
        [session begin];
    }
}

- (void) endAssessmentModeWithCallback:(id)callback
                              selector:(SEL)selector
{
    if (self.assessmentSession) {
        successCallback = callback;
        successSelector = selector;
        [self.assessmentSession end];
    } else {
        [self.delegate assessmentSessionDidEndWithCallback:callback selector:selector];
    }
}

- (void) assessmentSessionDidBegin:(AEAssessmentSession *)session
{
    [self.delegate assessmentSessionDidBeginWithCallback:successCallback selector:successSelector];
}

- (void) assessmentSession:(AEAssessmentSession *)session failedToBeginWithError:(NSError *)error
{
    self.assessmentSession = nil;
    [self.delegate assessmentSessionFailedToBeginWithError:error callback:successCallback selector:successSelector];
}

- (void) assessmentSessionDidEnd:(AEAssessmentSession *)session
{
    self.assessmentSession = nil;
    [self.delegate assessmentSessionDidEndWithCallback:successCallback selector:successSelector];

}

- (void) assessmentSession:(AEAssessmentSession *)session wasInterruptedWithError:(NSError *)error
{
    [self.delegate assessmentSessionWasInterruptedWithError:error];
    [session end];
}


@end
#endif
