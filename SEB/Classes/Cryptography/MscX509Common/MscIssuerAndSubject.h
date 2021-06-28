//
//  MscIssuerAndSubject.h
//  MscSCEP
//
//  Created by Microsec on 2014.02.07..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscX509Name.h"

@interface MscIssuerAndSubject : NSObject<NSCoding>

@property MscX509Name* issuer;
@property MscX509Name* subject;

- (BOOL)isEqualToMscIssuerAndSubject:(MscIssuerAndSubject*)otherMscIssuerAndSubject;

@end
