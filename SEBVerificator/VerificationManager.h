//
//  VerficationManager.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 13.07.22.
//  Copyright (c) 2010-2023 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Marco Lehre, Tobias Halbherr, Dirk Bauer, Kai Reuter,
//  Karsten Burger, Brigitte Schmucki, Oliver Rahs.
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
//  (c) 2010-2023 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VerificationManager : NSObject

- (NSArray<NSString *> *)associatedAppsForFile:(NSURL *)fileURL;
- (NSArray<NSString *> *)associatedAppsForFileExtension:(NSString *)pathExtension;
- (nullable NSURL *)defaultAppForFileExtension:(NSString *)pathExtension;
- (nullable NSURL *)defaultAppForURLScheme:(NSString *)mimeType;
- (NSArray<NSString *> *)associatedAppsForURLScheme:(NSString *)scheme;
- (BOOL)signedSEBExecutable:(NSString *)executablePath;

@end

NS_ASSUME_NONNULL_END
