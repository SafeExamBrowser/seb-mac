//
//  MscOpenSSLExtension.c
//  MscSCEP
//
//  Created by Microsec on 2014.02.05..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#include "MscOpenSSLExtension.h"
#include <openssl/asn1t.h>

ASN1_SEQUENCE(PKCS7_ISSUER_AND_SUBJECT) = {
    ASN1_SIMPLE(PKCS7_ISSUER_AND_SUBJECT, issuer, X509_NAME),
    ASN1_SIMPLE(PKCS7_ISSUER_AND_SUBJECT, subject, X509_NAME),
} ASN1_SEQUENCE_END(PKCS7_ISSUER_AND_SUBJECT)

IMPLEMENT_ASN1_FUNCTIONS(PKCS7_ISSUER_AND_SUBJECT)
