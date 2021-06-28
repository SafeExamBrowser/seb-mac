//
//  MscPKCS12.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.18..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscCertificate.h"

@interface MscPKCS12 : NSObject<NSCoding>

-(MscPKCS12*) init __attribute__((unavailable("please, use initWithContentsOfFile for initialization")));
-(id)initWithContentsOfFile:(NSString*)path error:(MscX509CommonError**)error;
-(id)initWithRSAKey:(MscRSAKey*)rsaKey certificate:(MscCertificate*)certificate password:(NSString*)password error:(MscX509CommonError**)error;
-(void)saveToPath:(NSString *)path error:(MscX509CommonError **)error;
-(MscCertificate*)getCertificateWithPassword:(NSString*)password error:(MscX509CommonError**)error;
-(MscRSAKey*)getRSAKeyWithPassword:(NSString*)password error:(MscX509CommonError**)error;
-(BOOL)isEqualToMscPKCS12:(MscPKCS12*)otherMscPKCS12;
-(NSData*)data;
-(BOOL)openWithPassword:(NSString*)password;
-(NSData*)signHash:(NSData*)hash password:(NSString*)password error:(MscX509CommonError**)error;

@end
