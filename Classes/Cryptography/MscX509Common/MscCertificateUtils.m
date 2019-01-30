//
//  MscCertificateUtils.m
//  MscSCEP
//
//  Created by Microsec on 2014.02.12..
//  Copyright (c) 2014 Microsec. All rights reserved.
//

#import "MscCertificateUtils.h"
#import <openssl/md5.h>
#import "MscX509CommonLocalException.h"
#import "MscCertificate_OpenSSL_X509.h"
#import "MscCertificateSigningRequest_OpenSSL_X509_REQ.h"
#import "NSString+MscASCIIExtension.h"

@implementation MscCertificateUtils

+(NSString*)getCertificatePublicKeyFingerPrint:(MscCertificate*)certificate error:(MscX509CommonError**)error {
	
    unsigned char *certificateData = NULL;
    unsigned char hash[MD5_DIGEST_LENGTH];
	MD5_CTX ctx;
    
    @try {
        
        
        long certificateDataLength = i2d_PUBKEY(X509_get_pubkey(certificate._x509), &certificateData);
        if (certificateDataLength < 1) {
            NSLog(@"Failed to read certificate, function i2d_PUBKEY returned with: %ld", certificateDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
        }
        
        MD5_Init(&ctx);
        MD5_Update(&ctx, certificateData, certificateDataLength);
        MD5_Final(hash, &ctx);
        
        NSMutableString *result = [[NSMutableString alloc] initWithCapacity: MD5_DIGEST_LENGTH * 2];
        
        for (int i = 0; i < MD5_DIGEST_LENGTH; i++) {
            [result appendFormat:@"%02X", hash[i]];
        }
        
        return result;
    }
    @catch (MscX509CommonLocalException *e) {
        *error = [MscX509CommonError errorWithCode:e.errorCode];
        return nil;
    }
    @finally {
        
        OPENSSL_free(certificateData);
    }
}


+(NSString*)getCertificateSigningRequestPublicKeyFingerPrint:(MscCertificateSigningRequest*)request error:(MscX509CommonError**)error {
    
    unsigned char *requestData = NULL;
    unsigned char hash[MD5_DIGEST_LENGTH];
	MD5_CTX ctx;
    
    @try {
        
        long requestDataLength = i2d_PUBKEY(X509_REQ_get_pubkey(request._request), &requestData);
        if (requestDataLength < 1) {
            NSLog(@"Failed to read certificate, function i2d_PUBKEY returned with: %ld", requestDataLength);
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToReadCertificate];
        }
        
        MD5_Init(&ctx);
        MD5_Update(&ctx, requestData, requestDataLength);
        MD5_Final(hash, &ctx);
        
        NSMutableString *result = [[NSMutableString alloc] initWithCapacity: MD5_DIGEST_LENGTH * 2];
        
        for (int i = 0; i < MD5_DIGEST_LENGTH; i++) {
            [result appendFormat:@"%02X", hash[i]];
        }
        
        return result;
    }
    @catch (MscX509CommonLocalException *e) {
        *error = [MscX509CommonError errorWithCode:e.errorCode];
        return nil;
    }
    @finally {
        
        OPENSSL_free(requestData);
    }
}

+(X509_NAME*)convertMscX509NameToX509_NAME:(MscX509Name*)subject {
    
    X509_NAME* name = NULL;
    
    @try {
        
        int returnCode;
        
        name = X509_NAME_new();
        if (!name) {
            NSLog(@"Failed to allocate memory for variable: name");
            @throw [MscX509CommonLocalException exceptionWithCode:FailedToAllocateMemory];
        }
        
        if (subject.commonName && ![subject.commonName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_commonName, MBSTRING_UTF8, (unsigned char*)[subject.commonName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.localityName && ![subject.localityName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_localityName, MBSTRING_UTF8, (unsigned char*)[subject.localityName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.stateOrProvinceName && ![subject.stateOrProvinceName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_stateOrProvinceName, MBSTRING_UTF8, (unsigned char*)[subject.stateOrProvinceName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.organizationName && ![subject.organizationName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_organizationName, MBSTRING_UTF8, (unsigned char*)[subject.organizationName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.organizationalUnitName && ![subject.organizationalUnitName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_organizationalUnitName, MBSTRING_UTF8, (unsigned char*)[subject.organizationalUnitName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.countryName && ![subject.countryName isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_countryName, MBSTRING_UTF8, (unsigned char*)[subject.countryName UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.streetAddress && ![subject.streetAddress isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_streetAddress, MBSTRING_UTF8, (unsigned char*)[subject.streetAddress UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.domainComponent && ![subject.domainComponent isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_domainComponent, MBSTRING_UTF8, (unsigned char*)[subject.domainComponent UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        if (subject.userid && ![subject.userid isEmpty]) {
            returnCode = X509_NAME_add_entry_by_NID(name, NID_userId, MBSTRING_UTF8, (unsigned char*)[subject.userid UTF8String], -1, -1, 0);
            if (returnCode != 1) {
                NSLog(@"Failed to convert certificate subject, function X509_NAME_add_entry_by_NID returned with %d", returnCode);
                @throw [MscX509CommonLocalException exceptionWithCode:FailedToConvertCertificateSubject];
            }
        }
        return name;
    }
    @catch (MscX509CommonLocalException *e) {
        
        X509_NAME_free(name);
        return nil;
    }
    
}

+(MscX509Name*)convertX509_NAMEToMscX509Name:(X509_NAME*)name {
    
    MscX509Name* subject = [[MscX509Name alloc] init];
    
    subject.commonName = [self getX509NameEntryWithNid:NID_commonName x509Name:name];
    subject.localityName = [self getX509NameEntryWithNid:NID_localityName x509Name:name];
    subject.stateOrProvinceName = [self getX509NameEntryWithNid:NID_stateOrProvinceName x509Name:name];
    subject.organizationName = [self getX509NameEntryWithNid:NID_organizationName x509Name:name];
    subject.organizationalUnitName = [self getX509NameEntryWithNid:NID_organizationalUnitName x509Name:name];
    subject.countryName = [self getX509NameEntryWithNid:NID_countryName x509Name:name];
    subject.streetAddress = [self getX509NameEntryWithNid:NID_streetAddress x509Name:name];
    subject.domainComponent = [self getX509NameEntryWithNid:NID_domainComponent x509Name:name];
    subject.userid = [self getX509NameEntryWithNid:NID_userId x509Name:name];
    subject.serialNumber = [self getX509NameEntryWithNid:NID_serialNumber x509Name:name];
    
    return subject;
}

+(NSString*)getX509NameEntryWithNid:(int)nid x509Name:(X509_NAME*)x509Name {
    
    unsigned char* buffer = NULL;
    
    @try {
        
        int returnCode;
        
        returnCode = X509_NAME_get_index_by_NID(x509Name, nid, -1);
        if (returnCode == -1) {
            
            return nil;
        }
        ASN1_STRING* asn1String = X509_NAME_ENTRY_get_data(X509_NAME_get_entry(x509Name, returnCode));
        if (!asn1String) {
            NSLog(@"Failed to convert certificate subject, function: X509_NAME_ENTRY_get_data");
            return nil;
        }
        returnCode = ASN1_STRING_to_UTF8(&buffer, asn1String);
        if (returnCode < 0) {
            NSLog(@"Failed to convert certificate subject, function ASN1_STRING_to_UTF8 returned with %d", returnCode);
            return nil;
        }
        return [NSString stringWithCString:(const char*)buffer encoding:NSUTF8StringEncoding];
    }
    @finally {
        OPENSSL_free(buffer);
    }
}

+(NSString*)convertASN1_INTEGERToNSString:(ASN1_INTEGER*)serialNumber {
    
    BIGNUM* bigNumer = NULL;
    
    @try {

        bigNumer = ASN1_INTEGER_to_BN(serialNumber, NULL);
        if (!bigNumer) {
            NSLog(@"Failed to convert serial number, function: ASN1_INTEGER_to_BN");
            return nil;
        }
        
        return [[NSString alloc] initWithCString:BN_bn2hex(bigNumer) encoding:NSASCIIStringEncoding];
    }
    @finally {
        
        BN_free(bigNumer);
    }
}

+(ASN1_INTEGER*)convertNSStringToASN1_INTEGER:(NSString*)serialNumber {
    
    ASN1_INTEGER* serial = NULL;
    BIGNUM* bigNumber = NULL;
    
    @try {

        BN_hex2bn(&bigNumber, [serialNumber ASCIIString]);
        if (!bigNumber) {
            NSLog(@"Failed to convert serial number, function: BN_hex2bn");
            return nil;
        }
        
        serial = BN_to_ASN1_INTEGER(bigNumber, NULL);
        if (!serial) {
            NSLog(@"Failed to convert serial number, function: BN_to_ASN1_INTEGER");
            return nil;
        }
        
        return serial;
        
    }
    @finally {
        
        BN_free(bigNumber);
    }
}

+(NSDate*)convertASN1_TIMEToNSDate:(ASN1_TIME*)asn1_time {
    
    NSString* dateString = [NSString stringWithCString:(const char*)asn1_time->data encoding:NSASCIIStringEncoding];
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    if ([dateString length] == 13) {
        [formatter setDateFormat:@"yyMMddHHmmss'Z'"];
    } else if ([dateString length] == 15) {
        [formatter setDateFormat:@"yyyyMMddHHmmssZ"];
    } else {
        NSLog(@"Failed to convert ASN1_TIME, format is unknown");
        return nil;
    }
    
    NSDate* d = [formatter dateFromString:dateString];
    
    return d;
}

+(NSString*)getFingerPrintAlgorithmNameByEnum: (FingerPrintAlgorithm)fingerPrintAlgorithm {
    switch (fingerPrintAlgorithm) {
        case FingerPrintAlgorithm_MD5:
            return @"MD5";
            break;
        case FingerPrintAlgorithm_SHA1:
            return @"SHA1";
            break;
        case FingerPrintAlgorithm_SHA256:
            return @"SHA256";
            break;
        case FingerPrintAlgorithm_SHA512:
            return @"SHA512";
            break;
        default:
            return @"SHA256";
            break;
    }
}

+(MscKeyUsage)getKeyUsageByIndex:(int)index {
    
    MscKeyUsage keyUsage;
    
    switch (index) {
        case 0:
            keyUsage = DigitalSignature;
            break;
        case 1:
            keyUsage = NonRepudiation;
            break;
        case 2:
            keyUsage = KeyEncipherment;
            break;
        case 3:
            keyUsage = DataEncipherment;
            break;
        case 4:
            keyUsage = KeyAgreement;
            break;
        case 5:
            keyUsage = KeyCertSign;
            break;
        case 6:
            keyUsage = CRLSign;
            break;
        case 7:
            keyUsage = EncipherOnly;
            break;
        case 8:
            keyUsage = DecipherOnly;
            break;
    }
    return keyUsage;
}

@end
