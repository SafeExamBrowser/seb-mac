//
//  SEBUserDefaultsController.m
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 07.11.11.
//  Copyright (c) 2010-2019 Daniel R. Schneider, ETH Zurich, 
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
//  (c) 2010-2019 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser 
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//  
//  Contributor(s): ______________________________________.
//

#import "SEBEncryptedUserDefaultsController.h"
#import "NSUserDefaultsController+SEBEncryptedUserDefaultsController.h"


@implementation SEBEncryptedUserDefaultsController


static SEBEncryptedUserDefaultsController *sharedSEBEncryptedUserDefaultsController = nil;

+ (SEBEncryptedUserDefaultsController *)sharedSEBEncryptedUserDefaultsController
{
	@synchronized(self)
	{
		if (sharedSEBEncryptedUserDefaultsController == nil)
		{
			sharedSEBEncryptedUserDefaultsController = [[self alloc] init];
		}
	}

	return sharedSEBEncryptedUserDefaultsController;
}
/*
+ (id)allocWithZone:(NSZone *)zone
{
	@synchronized(self)
	{
		if (sharedSEBEncryptedUserDefaultsController == nil)
		{
			sharedSEBEncryptedUserDefaultsController = [super allocWithZone:zone];
			return sharedSEBEncryptedUserDefaultsController;
		}
	}

	return nil;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
} */


// Getter Method used by bindings
- (id)valueForKeyPath:(NSString *)keyPath
{
    id object = [super secureValueForKeyPath:keyPath]; //call secure method used by bindings
	return object;
    
}


//- (id)valueForKey:(NSString *)key
//{
//    id object = [super valueForKey:key]; //call secure method used by bindings
//	return object;
//    
//}


// Setter method used by bindings
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    [super setSecureValue:value forKeyPath:keyPath]; //call secure method used by bindings
}


//- (void)setValue:(id)value forKey:(NSString *)key
//{
//    [super setValue:value forKey:key]; //call secure method used by bindings
//}


@end
