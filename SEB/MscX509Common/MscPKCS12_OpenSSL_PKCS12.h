//
//  MscPKCS12PKCS12.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.18..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/pkcs12.h>

@interface MscPKCS12 ()

@property PKCS12* _pkcs12;

-(id)initWithPKCS12:(PKCS12*)pkcs12;

@end
