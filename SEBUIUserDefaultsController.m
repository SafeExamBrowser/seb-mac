//
//  SEBUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 07.11.11.
//  Copyright (c) 2010-2012 Daniel R. Schneider, ETH Zurich, 
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
//  (C) 2010-2012 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBUIUserDefaultsController.h"


@implementation SEBUIUserDefaultsController

static SEBUIUserDefaultsController *sharedSEBUIUserDefaultsController = nil;

//@synthesize org_safeexambrowser_SEB_cryptoIdentities = _org_safeexambrowser_SEB_cryptoIdentities;


+ (SEBUIUserDefaultsController *)sharedSEBUIUserDefaultsController
{
	@synchronized(self)
	{
		if (sharedSEBUIUserDefaultsController == nil)
		{
			sharedSEBUIUserDefaultsController = [[self alloc] init];
		}
	}
    
	return sharedSEBUIUserDefaultsController;
}

/*- (id) init {
    self = [super init];
    [self setOrg_safeexambrowser_SEB_cryptoIdentities:[NSArray arrayWithObjects:NSLocalizedString(@"Fetching identities", nil), nil]];
    return self;
}
*/

- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByLinkPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"get generally blocked", nil), NSLocalizedString(@"open in same window", nil), NSLocalizedString(@"open in new window", nil), nil];
}

- (NSArray *) org_safeexambrowser_SEB_newBrowserWindowByScriptPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"get generally blocked", nil), NSLocalizedString(@"open in same window", nil), NSLocalizedString(@"open in new window", nil), nil];
}

- (NSArray *) org_safeexambrowser_SEB_chooseFileToUploadPolicies {
    return [NSArray arrayWithObjects:NSLocalizedString(@"manually with file requester", nil), NSLocalizedString(@"by attempting to upload same file downloaded before", nil), NSLocalizedString(@"by only allowing to upload the same file downloaded before", nil), nil];
}


- (NSArray *) org_safeexambrowser_SEB_cryptoIdentities {
    return [NSArray arrayWithObjects:NSLocalizedString(@"Fetching identities", nil), nil];
}


@end
