//
//  SEBSystemManager.h
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 14.11.13.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//


#import <Foundation/Foundation.h>

#import <IOKit/IOKitLib.h>
#import <sys/sysctl.h>

@class VarSystemInfo;

static NSString __unused *TempDownUploadLocation = @"tempDownUploadLocationURL";

@interface SEBSystemManager : NSObject {
    @private
    NSString *scLocation;
    NSString *scTempPath;
    NSString *downUploadTempPath;
    NSURL *downUploadTempURL;
}

@property (strong, nonatomic) VarSystemInfo *systemInfo;

- (BOOL) hasBuiltinDisplay;

// Cache current settings for Siri and dictation
- (void) cacheCurrentSystemSettings;

// Restore cached settings for Siri and dictation
- (BOOL) restoreSystemSettings;

- (void) preventScreenCapture;
- (BOOL) restoreScreenCapture;
- (void) adjustScreenCapture;

- (NSURL *) getStoredDirectoryURLWithKey:(NSString *)key;

- (NSURL *) getTempDownUploadDirectory;
- (BOOL) removeTempDownUploadDirectory;

- (BOOL) checkHTTPSProxySetting;

@end

@interface VarSystemInfo: NSObject
@property (readwrite, strong, nonatomic) NSString *sysName;
@property (readwrite, strong, nonatomic) NSString *sysUserName;
@property (readwrite, strong, nonatomic) NSString *sysFullUserName;
@property (readwrite, strong, nonatomic) NSString *sysOSName;
@property (readwrite, strong, nonatomic) NSString *sysOSVersion;
@property (readwrite, strong, nonatomic) NSNumber *sysPhysicalMemory;
@property (readwrite, strong, nonatomic) NSString *sysSerialNumber;
@property (readwrite, strong, nonatomic) NSString *sysUUID;
@property (readwrite, strong, nonatomic) NSString *sysModelID;
@property (readwrite, strong, nonatomic) NSString *sysModelName;
@property (readwrite, strong, nonatomic) NSString *sysProcessorName;
@property (readwrite, strong, nonatomic) NSNumber *sysProcessorSpeed;
@property (readwrite, strong, nonatomic) NSNumber *sysProcessorCount;
@property (readonly,  strong, nonatomic) NSString *getOSVersionInfo;

- (NSString *) _strIORegistryEntry:(NSString *)registryKey;
- (NSString *) _strControlEntry:(NSString *)ctlKey;
- (NSNumber *) _numControlEntry:(NSString *)ctlKey;
- (NSString *) _parseBrandName:(NSString *)brandName;
@end

static NSString* const kVarSysInfoVersionFormat  = @"%@.%@.%@ (%@)";
static NSString* const kVarSysInfoPlatformExpert = @"IOPlatformExpertDevice";

static NSString* const kVarSysInfoKeyOSVersion = @"kern.osrelease";
static NSString* const kVarSysInfoKeyOSBuild   = @"kern.osversion";
static NSString* const kVarSysInfoKeyModel     = @"hw.model";
static NSString* const kVarSysInfoKeyCPUCount  = @"hw.physicalcpu";
static NSString* const kVarSysInfoKeyCPUFreq   = @"hw.cpufrequency";
static NSString* const kVarSysInfoKeyCPUBrand  = @"machdep.cpu.brand_string";

static NSString* const kVarSysInfoMachineiMac        = @"iMac";
static NSString* const kVarSysInfoMachineMacmini     = @"Mac mini";
static NSString* const kVarSysInfoMachineMacBookAir  = @"MacBook Air";
static NSString* const kVarSysInfoMachineMacBookPro  = @"MacBook Pro";
static NSString* const kVarSysInfoMachineMacPro      = @"Mac Pro";

