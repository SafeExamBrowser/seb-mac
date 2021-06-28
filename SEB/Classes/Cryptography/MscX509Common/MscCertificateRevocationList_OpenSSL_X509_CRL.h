//
//  MscCertificateRevocationListX509_CRL.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/x509.h>

@interface MscCertificateRevocationList ()

@property X509_CRL* _crl;

-(id)initWithX509_CRL:(X509_CRL*)crl;

@end
