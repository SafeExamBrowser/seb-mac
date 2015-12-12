//
//  SEBConfigFileCredentials.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 11/12/15.
//
//

#import <Foundation/Foundation.h>

@interface SEBConfigFileCredentials : NSObject

@property (strong) NSString *password;
@property (readwrite) BOOL passwordIsHash;
@property (readwrite) SecKeyRef keyRef;

@end
