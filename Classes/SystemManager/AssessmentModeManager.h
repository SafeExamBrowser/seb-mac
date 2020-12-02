//
//  AssessmentModeManager.h
//  Safe Exam Browser
//
//  Created by Daniel R. Schneider on 02.12.20.
//

#import <Foundation/Foundation.h>

#import <AutomaticAssessmentConfiguration/AutomaticAssessmentConfiguration.h>

NS_ASSUME_NONNULL_BEGIN

@interface AssessmentModeManager: NSObject <AEAssessmentSessionDelegate>

@property(strong, nonatomic) AEAssessmentSession *assessmentSession API_AVAILABLE(macosx(10.15.4));

@end

NS_ASSUME_NONNULL_END
