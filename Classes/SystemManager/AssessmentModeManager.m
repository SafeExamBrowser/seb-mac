//
//  AssessmentModeManager.m
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 02.12.20.
//

#import "AssessmentModeManager.h"

@implementation AssessmentModeManager

- (void) beginAssessmentMode
{
    if (@available(macOS 10.15.4, *)) {
        AEAssessmentConfiguration *config = [AEAssessmentConfiguration new];
        AEAssessmentSession *session = [[AEAssessmentSession alloc] initWithConfiguration:config];
        session.delegate = self;
    }
}

@end
