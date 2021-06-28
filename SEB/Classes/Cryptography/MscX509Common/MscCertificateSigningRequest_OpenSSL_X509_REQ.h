//
//  MscCertificateSigningRequestX509_REQ.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscCertificateSigningRequest.h"
#import <openssl/x509.h>

@interface MscCertificateSigningRequest ()

@property X509_REQ* _request;

@end
