//
//  SEBCertServices.m
//  SafeExamBrowser
//
//  Created by dmcd on 12/02/2016.
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
                        
                        if (dataString)
                        {
                            NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:0];
                            
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
                            NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:0];
                            
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
                            NSData *data = [[NSData alloc] initWithBase64EncodedString:dataString options:0];
                            
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
