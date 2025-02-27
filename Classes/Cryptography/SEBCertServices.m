//
//  SEBCertServices.m
//  SafeExamBrowser
//
//  Created by dmcd on 12/02/2016.
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for macOS.
//
//  The Initial Developer of the Original Code is dmcd, Copyright
//  (c) 2015-2016 Janison
//
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): Daniel R. Schneider.
//

#import "SEBCertServices.h"


static SEBCertServices *gSharedInstance = nil;


@interface SEBCertServices ()

@property (nonatomic, strong) NSMutableArray *embeddedCACerts;
@property (nonatomic, strong) NSMutableArray *embeddedTLSCerts;
@property (nonatomic, strong) NSMutableArray *embeddedDebugCerts;
@property (nonatomic, strong) NSMutableArray *embeddedDebugCertNames;

@end


@implementation SEBCertServices

+ (instancetype)sharedInstance
{
    @synchronized(self)
    {
        if (!gSharedInstance)
        {
            gSharedInstance = [[self alloc] init];
        }
    }
    
    return gSharedInstance;
}

- (instancetype)init
{
    @synchronized(self)
    {
        if (!gSharedInstance)
        {
            if (self = [super init])
            {
                gSharedInstance = self;
            }
        }
    }
    
    return gSharedInstance;
}


- (void)flushCachedCertificates
{
    self.embeddedCACerts = nil;
    self.embeddedTLSCerts = nil;
    self.embeddedDebugCerts = nil;
    self.embeddedDebugCertNames = nil;
}


- (NSArray *)caCerts
{
    if (!self.embeddedCACerts)
    {
        self.embeddedCACerts = [NSMutableArray array];
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        NSArray *array = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
        
        if (array)
        {
            for (NSDictionary *dict in array)
            {
                NSNumber *type = [dict objectForKey:@"type"];
                
                if (type)
                {
                    if ([type integerValue] == certificateTypeCA)
                    {
                        NSString *dataString = [dict objectForKey:@"certificateDataBase64"];
                        if (!dataString) {
                            dataString = [dict objectForKey:@"certificateDataWin"];
                        }
                        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                        if (dataString)
                        {
                            NSData *data;
                            data = [[NSData alloc] initWithBase64EncodedString:dataString
                                                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
                            if (data)
                            {
                                SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)data);
                                
                                if (cert)
                                {
                                    [self.embeddedCACerts addObject:
                                     (__bridge id _Nonnull)(cert)];
                                    CFRelease(cert);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return [self.embeddedCACerts copy];
}


- (NSArray *)tlsCerts
{
    if (!self.embeddedTLSCerts)
    {
        self.embeddedTLSCerts = [NSMutableArray array];
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        NSArray *array = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
        
        if (array)
        {
            for (NSDictionary *dict in array)
            {
                NSNumber *type = [dict objectForKey:@"type"];
                
                if (type)
                {
                    if ([type integerValue] == certificateTypeSSL)
                    {
                        NSString *dataString = [dict objectForKey:@"certificateDataBase64"];
                        if (!dataString) {
                            dataString = [dict objectForKey:@"certificateDataWin"];
                        }
                        
                        if (dataString)
                        {
                            NSData *data;
                            data = [[NSData alloc] initWithBase64EncodedString:dataString
                                                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
                            if (data)
                            {
                                SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)data);
                                
                                if (cert)
                                {
                                    [self.embeddedTLSCerts addObject:(__bridge id _Nonnull)(cert)];
                                    CFRelease(cert);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return [self.embeddedTLSCerts copy];
}


- (NSArray *)debugCerts
{
    if (!self.embeddedDebugCerts)
    {
        self.embeddedDebugCerts = [NSMutableArray array];
        self.embeddedDebugCertNames = [NSMutableArray array];
        
        NSUserDefaults *preferences = [NSUserDefaults standardUserDefaults];
        
        NSArray *array = [preferences secureObjectForKey:@"org_safeexambrowser_SEB_embeddedCertificates"];
        
        if (array)
        {
            for (NSDictionary *dict in array)
            {
                NSNumber *type = [dict objectForKey:@"type"];
                
                if (type)
                {
                    if ([type integerValue] == certificateTypeSSLDebug)
                    {
                        NSString *dataString = [dict objectForKey:@"certificateDataBase64"];
                        
                        if (dataString)
                        {
                            NSData *data;
                            data = [[NSData alloc] initWithBase64EncodedString:dataString
                                                                               options:NSDataBase64DecodingIgnoreUnknownCharacters];
#pragma clang diagnostic pop
                            if (data)
                            {
                                SecCertificateRef cert = SecCertificateCreateWithData(NULL, (CFDataRef)data);
                                
                                if (cert)
                                {
                                    [self.embeddedDebugCerts addObject:(__bridge id _Nonnull)(cert)];
                                    CFRelease(cert);
                                    [self.embeddedDebugCertNames addObject:[dict objectForKey:@"name"]];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    return [self.embeddedDebugCerts copy];
}


- (NSArray *)debugCertNames
{
    return [self.embeddedDebugCertNames copy];
}


@end
