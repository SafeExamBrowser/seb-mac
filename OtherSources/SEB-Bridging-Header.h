//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import "NSUserDefaults+SEBEncryptedUserDefaults.h"
#import "WKWebView+SEBEvaluateJavaScript.h"
#import "Constants.h"
#import "MyGlobals.h"
#import "SEBAbstractWebView.h"
#import "SEBURLFilter.h"
#import "SEBBatteryController.h"
#import "SEBWiFiController.h"
#import "SEBSystemManager.h"
#import "SEBURLFilter.h"
#if DEBUG
// Exposes SEBCryptor's private Config Key value serializer to the (DEBUG-only)
// test-support shim; see SEBCryptorConfigKeyTestSupport.swift.
#import "SEBCryptor+Testing.h"
// Exposes SEBKeychainManager's password hashing/comparison to the (DEBUG-only)
// test-support shim; see SEBKeychainManagerTestSupport.swift.
#import "SEBKeychainManager.h"
// Exposes the config-import path to the (DEBUG-only) lockdownModePolicy migration
// test-support shim; see SEBLockdownModePolicyMigrationTestSupport.swift.
#import "SEBConfigFileManager.h"
// Exposes the server-trust authorization decision to the (DEBUG-only) trust
// test-support shim; see SEBBrowserControllerTrustTestSupport.swift.
#import "SEBBrowserController+Testing.h"
// Exposes the SEB version restriction check to the (DEBUG-only) test-support
// shim; see SEBAllowedSEBVersionsTestSupport.swift.
#import "SEBAllowedSEBVersions.h"
#endif
