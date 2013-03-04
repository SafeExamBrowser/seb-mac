//
//  Constants.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 29.12.11.
//  Copyright (c) 2010-2013 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
//  Dirk Bauer, Karsten Burger, Marco Lehre, 
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
//  (c) 2010-2013 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#ifndef SafeExamBrowser_Constants_h
#define SafeExamBrowser_Constants_h

enum {
    browserViewModeWindow                       = 0,
    browserViewModeFullscreen                   = 1
};
typedef NSUInteger browserViewModes;


enum {
    manuallyWithFileRequester                   = 0,
    attemptUploadSameFileDownloadedBefore       = 1,
    onlyAllowUploadSameFileDownloadedBefore     = 2
};
typedef NSUInteger chooseFileToUploadPolicies;


enum {
    FetchingIdentities                   = 0
};
typedef NSUInteger cryptoIdentities;


static NSString __unused *userDefaultsMasala = @"D𝈭il𝈖Ch𝈒a𝉇ht𝈁a𝉈Hai1972";


enum {
    getGenerallyBlocked                         = 0,
    openInSameWindow                            = 1,
    openInNewWindow                             = 2
};
typedef NSUInteger newBrowserWindowPolicies;


enum {
    sebPurposePolicyStartingExam                = 0,
    sebPurposePolicyConfiguringClient           = 1
};
typedef NSUInteger sebPurposePolicies;


enum {
    ignoreService                               = 0,
    indicateMissingService                      = 1,
    forceSebService                             = 2
};
typedef NSUInteger sebServicePolicies;


enum {
    urlFilterActionBlock                        = 0,
    urlFilterActionAllow                        = 1,
    urlFilterActionSkip                         = 2,
    urlFilterActionAnd                          = 3,
    urlFilterActionOr                           = 4
};
typedef NSUInteger urlFilterRuleActions;


enum {
    SEBEnterPasswordCancel                      = 0,
    SEBEnterPasswordOK                          = 1
};
typedef NSUInteger SEBEnterPasswordResponse;


#endif
