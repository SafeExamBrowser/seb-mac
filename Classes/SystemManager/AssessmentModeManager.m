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

- (BOOL) beginAssessmentMode
{
    DDLogDebug(@"%s", __FUNCTION__);
    
    if (self.assessmentSession && self.assessmentSession.active) {
        DDLogWarn(@"Assessment session is already active!");
        return NO;
    }
    
    AEAssessmentConfiguration *config = [AEAssessmentConfiguration new];

    if (@available(macOS 12, *)) {
        AEAssessmentApplication *calculator = [[AEAssessmentApplication alloc] initWithBundleIdentifier:@"com.apple.calculator"];
        AEAssessmentParticipantConfiguration *calculatorConfig = [AEAssessmentParticipantConfiguration new];
        calculatorConfig.allowsNetworkAccess = NO;
        [config setConfiguration:calculatorConfig forApplication:calculator];

        AEAssessmentApplication *excel = [[AEAssessmentApplication alloc] initWithBundleIdentifier:@"com.microsoft.Excel" teamIdentifier:@"UBF8T346G9"];
        AEAssessmentParticipantConfiguration *excelConfig = [AEAssessmentParticipantConfiguration new];
        excelConfig.allowsNetworkAccess = NO;
        [config setConfiguration:excelConfig forApplication:excel];

        AEAssessmentApplication *pages = [[AEAssessmentApplication alloc] initWithBundleIdentifier:@"com.apple.iWork.Pages" teamIdentifier:@"K36BKF7T3D"];
        AEAssessmentParticipantConfiguration *pagesConfig = [AEAssessmentParticipantConfiguration new];
        pagesConfig.allowsNetworkAccess = NO;
        [config setConfiguration:pagesConfig forApplication:pages];
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
{
    DDLogDebug(@"%s callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));

    if (self.assessmentSession && self.assessmentSession.active) {
        successCallback = callback;
        successSelector = selector;
        DDLogDebug(@"%s: Ending assessment session, set callback: %@ selector: %@", __FUNCTION__, callback, NSStringFromSelector(selector));
        [self.delegate assessmentSessionWillEnd];

        [self.assessmentSession end];
        return YES;
    } else {
        DDLogWarn(@"Assessment session is not active!");
        [self.delegate assessmentSessionWillEnd];
        [self.delegate assessmentSessionDidEndWithCallback:callback selector:selector];
        return NO;
    }
}


- (void) assessmentSessionDidBegin:(AEAssessmentSession *)session
{
    DDLogDebug(@"%s", __FUNCTION__);
    [self.delegate assessmentSessionDidBeginWithCallback:successCallback selector:successSelector];
}

- (void) assessmentSession:(AEAssessmentSession *)session failedToBeginWithError:(NSError *)error
{
    DDLogDebug(@"%s error: %@", __FUNCTION__, error);
    self.assessmentSession = nil;
    [self.delegate assessmentSessionFailedToBeginWithError:error callback:successCallback selector:successSelector];
}

- (void) assessmentSessionDidEnd:(AEAssessmentSession *)session
{
    DDLogDebug(@"%s: Will call delegate assessmentSessionDidEndWithCallback: %@ selector: %@", __FUNCTION__, successCallback, NSStringFromSelector(successSelector));
    self.assessmentSession = nil;
    if (successCallback) {
        id callback = successCallback;
        successCallback = nil;
        DDLogDebug(@"%s: Reset callback for delegate assessmentSessionDidEndWithCallback:selector: to %@", __FUNCTION__, successCallback);
        [self.delegate assessmentSessionDidEndWithCallback:callback selector:successSelector];
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
