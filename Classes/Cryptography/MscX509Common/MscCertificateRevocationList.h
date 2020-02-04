//
//  MscCertificateRevocationList.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MscCertificateRevocationList : NSObject<NSCoding>

-(id)init __attribute__((unavailable("please, use initWithContentsOfFile for initialization")));
-(id)initWithContentsOfFile:(NSString*)path error:(NSError**)error;
-(void)saveToPath:(NSString*)path error:(NSError**)error;
-(BOOL)isEqualToMscCertificateRevocationList:(MscCertificateRevocationList*)otherMscCertificateRevocationList;

@end
