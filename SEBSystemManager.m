//
//  SEBSystemManager.m
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 14.11.13.
//  Copyright (c) 2010-2014 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
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
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2014 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import "SEBSystemManager.h"
#include <SystemConfiguration/SystemConfiguration.h>

Boolean GetHTTPSProxySetting(char *host, size_t hostSize, UInt16 *port);

@implementation SEBSystemManager


Boolean GetHTTPSProxySetting(char *host, size_t hostSize, UInt16 *port)
// Returns the current HTTPS proxy settings as a C string
// (in the buffer specified by host and hostSize) and
// a port number.
{
    Boolean            result = 0;
    CFDictionaryRef    proxyDict;
    CFMutableDictionaryRef proxyDictSet;
    CFNumberRef        enableNum;
    int                enable;
    CFStringRef        hostStr;
    CFNumberRef        portNum = 0;
    int                portInt;
    SCDynamicStoreRef proxyStore;
    
    assert(host != NULL);
    assert(port != NULL);
    
    // Get the dictionary.
    
    printf("hostSize=%zu\n",hostSize);
    proxyStore =
    SCDynamicStoreCreate(NULL,CFSTR("NetScaler"),NULL,NULL);
    proxyDict = SCDynamicStoreCopyProxies(proxyStore);
    result = (proxyDict != NULL);
    
    // Get the enable flag.  This isn't a CFBoolean, but a CFNumber.
    
    if (result) {
        enableNum = (CFNumberRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSEnable);
        
        result = (enableNum != NULL)
        && (CFGetTypeID(enableNum) ==
            CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(enableNum,
                                  kCFNumberIntType,
                                  &enable) && (enable != 0);
    }
    
    // Get the proxy host.  DNS names must be in ASCII.  If you
    // put a non-ASCII character  in the "Secure Web Proxy"
    // field in the Network preferences panel, the CFStringGetCString
    // function will fail and this function will return false.
    
    if (result) {
        hostStr = (CFStringRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSProxy);
        
        result = (hostStr != NULL)
        && (CFGetTypeID(hostStr) ==
            CFStringGetTypeID());
    }
    if (result) {
        result = CFStringGetCString(hostStr, host,
                                    (CFIndex) hostSize,
                                    kCFStringEncodingASCII);
    }
    
    // Get the proxy port.
    
    if (result) {
        portNum = (CFNumberRef)
        CFDictionaryGetValue(proxyDict,
                             kSCPropNetProxiesHTTPSPort);
        
        result = (portNum != NULL)
        && (CFGetTypeID(portNum) ==
            CFNumberGetTypeID());
    }
    if (result) {
        result = CFNumberGetValue(portNum,
                                  kCFNumberIntType, &portInt);
    }
    if (result) {
        *port = (UInt16) portInt;
    }
    
    //proxyDictSet = SCDynamicStoreCopyProxies(NULL);
    proxyDictSet =
    CFDictionaryCreateMutableCopy(NULL,0,proxyDict);
    CFDictionarySetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSProxy,CFSTR("127.0.0.1"));
    enable = 1;
    CFDictionarySetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSEnable,CFNumberCreate(NULL,kCFNumberIntType,&enable));
    hostStr = (CFStringRef)
    CFDictionaryGetValue(proxyDictSet,
                         kSCPropNetProxiesHTTPSProxy);
    result = CFStringGetCString(hostStr, host,
                                (CFIndex) hostSize,
                                kCFStringEncodingASCII);
    printf("HTTPS-Set proxy host = %s\n",host);
    
    printf("now we try the new thing...\n");
    
    //if(SCDynamicStoreSetValue(NULL,kSCPropNetProxiesHTTPSProxy,CFSTR("127.0.0.1")))
    {
        
        if(SCDynamicStoreSetValue(proxyStore,kSCPropNetProxiesHTTPSProxy,proxyDictSet))
        {
            printf("store updated successfully...\n");
        }else {
            printf("store NOT updated successfully...\n");
            printf("Error is %s\n",SCErrorString(SCError()));
        }
        
        // Clean up.
        
        if (proxyDict != NULL) {
            CFRelease(proxyDict);
        }
        if ( ! result ) {
            *host = 0;
            *port = 0;
        }
        return result;
    }
}

- (BOOL) checkHTTPSProxySetting
{
    UInt16 port;
    char host[100];
    
    BOOL worked = GetHTTPSProxySetting(host,sizeof(host),&port);
    printf("HTTPS proxy host = %s\n",host);
    printf("HTTPS proxy port = %d\n",port);
    return worked;
}
//    int main(int argc, char** argv) {
//        UInt16 port;
//        char host[100];
//        
//        GetHTTPSProxySetting(host,sizeof(host),&port);
//        printf("HTTPS proxy host = %s\n",host);
//        printf("HTTPS proxy host = %d\n",port);
//    }

@end
