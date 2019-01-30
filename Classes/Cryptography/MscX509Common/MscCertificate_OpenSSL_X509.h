//
//  MscCertificateX509.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/x509.h>

@interface MscCertificate ()

@property X509* _x509;

-(id)initWithX509:(X509*)x509;

@end
