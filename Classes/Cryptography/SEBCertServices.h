//
//  SEBCertServices.h
//  SafeExamBrowser
//
//  Created by dmcd on 12/02/2016.
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
//  The Original Code is Safe Exam Browser for macOS.
//
//  The Initial Developer of the Original Code is dmcd Copyright
//  (c) 2015-2016 Janison
//
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): Daniel R. Schneider.
//

#import <Foundation/Foundation.h>

@interface SEBCertServices : NSObject

+ (instancetype)sharedInstance;

// Call this if the certificates in the client config are updated
- (void)flushCachedCertificates;

- (NSArray *)caCerts;
- (NSArray *)tlsCerts;
- (NSArray *)debugCerts;
- (NSArray *)debugCertNames;

@end
