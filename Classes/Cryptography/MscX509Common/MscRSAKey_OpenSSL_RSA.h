//
//  MscRSAKeyRSA.h
//  MscSCEP
//
//  Created by Microsec on 2014.01.27..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/rsa.h>

@interface MscRSAKey ()

@property(readonly) RSA* _rsa;
@property(readonly) EVP_PKEY* _evp_pkey;

-(id)initWithRSA:(RSA*)rsa;
-(id)initWithEVP_PKEY:(EVP_PKEY*)evp_pkey;

@end
