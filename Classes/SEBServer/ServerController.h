//
//  ServerController.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 25.01.19.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Foundation/Foundation.h>
#import "SafeExamBrowser-Swift.h"

@class SEBServerController;

NS_ASSUME_NONNULL_BEGIN

@protocol ServerControllerDelegate <NSObject>

- (void) didSelectExamWithExamId:(NSString *)examId url:(NSString *)url;
- (void) storeNewSEBSettings:(NSData *)configData;
- (void) loginToExam:(NSString *)url;
- (void) didEstablishSEBServerConnection;
- (void) serverSessionQuitRestart:(BOOL)restart;
- (void) closeServerView:(id)sender;
- (void) didCloseSEBServerConnectionRestart:(BOOL)restart;

@optional
- (void) startProctoringWithAttributes:(NSDictionary *)attributes;
- (void) reconfigureWithAttributes:(NSDictionary *)attributes;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) examineCookies:(nonnull NSArray<NSHTTPCookie *> *)cookies;

@end


@interface ServerController : NSObject <SEBServerControllerDelegate>
{
    @private
    NSString *lmsLoginLastUsername;
    NSString *lmsLoginBaseURL;
}

@property (weak) id<ServerControllerDelegate> delegate;

@property (strong) NSDictionary *sebServer;
@property (strong, nonatomic) SEBServerController *sebServerController;

- (BOOL) connectToServer:(NSURL *)url withConfiguration:(NSDictionary *)sebServerConfiguration;
- (void) startExamFromServer;
- (void) loginToExam:(NSString * _Nonnull)url;
- (void) examSelected:(NSString * _Nonnull)examId url:(NSString * _Nonnull)url;
- (void) examineCookies:(NSArray<NSHTTPCookie *>*)cookies;
- (void) shouldStartLoadFormSubmittedURL:(NSURL *)url;
- (void) sendLogEventWithLogLevel:(NSUInteger)logLevel
                        timestamp: (NSString *)timestamp
                     numericValue:(double)numericValue
                          message:(NSString *)message;
- (void) quitSessionWithRestart:(BOOL)restart;

- (void) loginToExamAborted;

@end

NS_ASSUME_NONNULL_END
