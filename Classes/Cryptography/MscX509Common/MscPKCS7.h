//
//  MscPKCS7.h
//  MscX509Common
//
//  Created by Lendvai Richárd on 2015. 02. 23..
//  Copyright (c) 2015. Microsec. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MscPKCS12.h"

@interface MscPKCS7 : NSObject

-(NSData*)signData:(NSData*)data key:(MscPKCS12*)pkcs12 password:(NSString*)password error:(MscX509CommonError**)error;

@end
