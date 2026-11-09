//
//  SEBLockdownModePolicyMigrationTests.swift
//  SafeExamBrowserTests
//
//  Verifies the migration of pre-lockdownModePolicy configs (which only had the
//  boolean enableMacOSAAC) to the lockdownModePolicy setting.
//
//  Layer 1 tests the pure AAC-support decision in isolation.
//  Layer 2 drives the real config-import path (SEBConfigFileManager
//  -storeIntoUserDefaults:) against in-memory private user defaults, guarding the
//  bug that was fixed: the migration must run against the ORIGINALLY loaded config
//  (before default values are merged in for the Config Key) and must not have its
//  result overwritten by the default-merged values.
//
//  Uses XCTest rather than the Testing framework to match the other unit tests in
//  this target (see SEBConfigKeyDoubleTests).
//

import XCTest
import Safe_Exam_Browser

final class SEBLockdownModePolicyMigrationTests: XCTestCase {

    // lockdownModePolicy raw values, see Constants.h
    private let lockdownModePolicyAutomatic = 0
    private let lockdownModePolicyEnforceClassic = 1
    private let lockdownModePolicyEnforceAAC = 2

    // MARK: - Layer 1: pure AAC-support decision

    private func aacSupported(minMacOSVersion: Int = 0,
                              checkFullVersion: Bool,
                              versionMajor: Int = 0,
                              versionMinor: Int = 0,
                              aacDnsPrePinning: Bool = false) -> Bool {
        SEBLockdownModePolicyMigrationTestSupport.aacSupported(
            minMacOSVersion: minMacOSVersion,
            checkFullVersion: checkFullVersion,
            versionMajor: versionMajor,
            versionMinor: versionMinor,
            aacDnsPrePinning: aacDnsPrePinning)
    }

    // Full version number check (allowMacOSVersionNumberCheckFull == true)
    func testFullVersion_major13_isSupported() {
        XCTAssertTrue(aacSupported(checkFullVersion: true, versionMajor: 13, versionMinor: 0))
    }

    func testFullVersion_macOS12_1_isSupported() {
        XCTAssertTrue(aacSupported(checkFullVersion: true, versionMajor: 12, versionMinor: 1))
    }

    func testFullVersion_macOS12_0_withoutPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(checkFullVersion: true, versionMajor: 12, versionMinor: 0))
    }

    func testFullVersion_macOS11_withPrePinning_isSupported() {
        XCTAssertTrue(aacSupported(checkFullVersion: true, versionMajor: 11, versionMinor: 0, aacDnsPrePinning: true))
    }

    func testFullVersion_macOS11_withoutPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(checkFullVersion: true, versionMajor: 11, versionMinor: 5, aacDnsPrePinning: false))
    }

    func testFullVersion_macOS10_15_withPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(checkFullVersion: true, versionMajor: 10, versionMinor: 15, aacDnsPrePinning: true))
    }

    // Minimum-version-index check (allowMacOSVersionNumberCheckFull == false).
    // Indices: SEBMinMacOS10_15 = 8, SEBMinMacOS11 = 9, SEBMinMacOS12 = 10 (see Constants.h)
    func testMinVersion_above12_isSupported() {
        XCTAssertTrue(aacSupported(minMacOSVersion: 11, checkFullVersion: false))
    }

    func testMinVersion_exactly12_withoutPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(minMacOSVersion: 10, checkFullVersion: false, aacDnsPrePinning: false))
    }

    func testMinVersion_exactly12_withPrePinning_isSupported() {
        XCTAssertTrue(aacSupported(minMacOSVersion: 10, checkFullVersion: false, aacDnsPrePinning: true))
    }

    func testMinVersion_exactly11_withPrePinning_isSupported() {
        XCTAssertTrue(aacSupported(minMacOSVersion: 9, checkFullVersion: false, aacDnsPrePinning: true))
    }

    func testMinVersion_exactly11_withoutPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(minMacOSVersion: 9, checkFullVersion: false, aacDnsPrePinning: false))
    }

    func testMinVersion_10_15_withPrePinning_isNotSupported() {
        XCTAssertFalse(aacSupported(minMacOSVersion: 8, checkFullVersion: false, aacDnsPrePinning: true))
    }

    // MARK: - Layer 2: full import path (private in-memory user defaults)

    private func importAndRead(_ settings: [String: Any]) -> (policy: Int, allowOpenAndSavePanel: Bool) {
        let result = SEBLockdownModePolicyMigrationTestSupport.importSettingsAndReadMigratedValues(settings)
        let policy = result["lockdownModePolicy"]?.intValue ?? -1
        let allow = result["allowOpenAndSavePanel"]?.boolValue ?? false
        return (policy, allow)
    }

    // If the loaded config already contains lockdownModePolicy, the migration must not run:
    // the explicit value has to survive, even though enableMacOSAAC would otherwise map to AAC.
    func testExistingLockdownModePolicyIsNotMigrated() {
        let (policy, _) = importAndRead([
            "enableMacOSAAC": true,
            "lockdownModePolicy": lockdownModePolicyEnforceClassic,
        ])
        XCTAssertEqual(policy, lockdownModePolicyEnforceClassic)
    }

    // The regression case: an old AAC config (enableMacOSAAC == true, no lockdownModePolicy)
    // on a supported macOS version must migrate to lockdownModePolicyEnforceAAC — and must NOT
    // be overwritten by the default (Automatic) that the default-merged dict writes first.
    func testEnableMacOSAACSupportedMigratesToEnforceAAC() {
        let (policy, _) = importAndRead([
            "enableMacOSAAC": true,
            "allowMacOSVersionNumberCheckFull": false,
            "minMacOSVersion": 11, // above SEBMinMacOS12 -> AAC supported
        ])
        XCTAssertEqual(policy, lockdownModePolicyEnforceAAC)
    }

    // An old AAC config on an unsupported macOS version must stay at the default
    // (Automatic) — the migration must not force EnforceAAC.
    func testEnableMacOSAACUnsupportedStaysAutomatic() {
        let (policy, _) = importAndRead([
            "enableMacOSAAC": true,
            "allowMacOSVersionNumberCheckFull": false,
            "minMacOSVersion": 8, // SEBMinMacOS10_15, no pre-pinning -> not supported
            "aacDnsPrePinning": false,
        ])
        XCTAssertEqual(policy, lockdownModePolicyAutomatic)
    }

    // An old classic (non-AAC) config must get allowOpenAndSavePanel forced to true, so the
    // file chooser keeps working if the automatic policy activates AAC in the session.
    func testDisabledMacOSAACForcesAllowOpenAndSavePanel() {
        let (_, allow) = importAndRead([
            "enableMacOSAAC": false,
        ])
        XCTAssertTrue(allow)
    }
}
