//
//  MscOpenSSLExtension.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.05..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#ifndef MscSCEP_MscOpenSSLExtension_h
#define MscSCEP_MscOpenSSLExtension_h

#include <openssl/x509.h>

typedef struct {
	X509_NAME *issuer;
	X509_NAME *subject;
} PKCS7_ISSUER_AND_SUBJECT;

DECLARE_ASN1_FUNCTIONS(PKCS7_ISSUER_AND_SUBJECT)

#endif
