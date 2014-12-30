//
//  SEBUserDefaultsController.h
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 07.11.11.
//  Copyright (c) 2010-2015 Daniel R. Schneider, ETH Zurich, 
//  Educational Development and Technology (LET), 
//  based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, 
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
//  (c) 2010-2015 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//



@interface SEBUIUserDefaultsController : NSUserDefaultsController {
    NSArray *org_safeexambrowser_SEB_cryptoIdentities;
}

//@property(nonatomic, strong) NSArray *org_safeexambrowser_SEB_cryptoIdentities;


+ (SEBUIUserDefaultsController *)sharedSEBUIUserDefaultsController;

- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByLinkPolicies;
- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByScriptPolicies;

- (NSArray *) org_safeexambrowser_SEB_chooseFileToUploadPolicies;

- (NSArray *) org_safeexambrowser_SEB_cryptoIdentities;

- (NSArray *) org_safeexambrowser_SEB_browserWindowPositionings;

- (NSArray *) org_safeexambrowser_SEB_proxyProtocols;

- (NSArray *) org_safeexambrowser_SEB_sebServicePolicies;

- (NSArray *) org_safeexambrowser_SEB_URLFilterRuleActions;

- (NSArray *) org_safeexambrowser_SEB_logLevels;

- (NSArray *) org_safeexambrowser_SEB_operatingSystems;

@end
