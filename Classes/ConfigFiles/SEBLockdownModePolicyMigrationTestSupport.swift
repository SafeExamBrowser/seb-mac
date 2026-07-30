//
//  SEBLockdownModePolicyMigrationTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge that exposes the lockdownModePolicy settings migration to the
//  Swift unit test target. The test target links the app module but cannot see
//  Objective-C classes (like the NSUserDefaults+SEBEncryptedUserDefaults category
//  or SEBConfigFileManager) directly, so this small @objc public wrapper (part of
//  the app's Swift module) provides access.
//  Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation

@objc public final class SEBLockdownModePolicyMigrationTestSupport: NSObject {

    /// Layer 1 — the pure AAC-support decision, with no NSUserDefaults side effects.
    /// See +[NSUserDefaults aacSupportedForMinMacOSVersion:...].
    @objc public static func aacSupported(minMacOSVersion: Int,
                                          checkFullVersion: Bool,
                                          versionMajor: Int,
                                          versionMinor: Int,
                                          aacDnsPrePinning: Bool) -> Bool {
        return UserDefaults.aacSupported(forMinMacOSVersion: minMacOSVersion,
                                         checkFullVersion: checkFullVersion,
                                         versionMajor: versionMajor,
                                         versionMinor: versionMinor,
                                         aacDnsPrePinning: aacDnsPrePinning)
    }

    /// Layer 2 — runs the real config-import path (SEBConfigFileManager
    /// -storeIntoUserDefaults:) against in-memory private user defaults, so the
    /// wiring is exercised end to end without touching the user's real preferences.
    /// Returns the resulting values of the two keys the migration can change.
    /// - Parameter settings: the loaded .seb settings (keys WITHOUT the
    ///   "org_safeexambrowser_SEB_" prefix), as they would arrive from a config file.
    @objc public static func importSettingsAndReadMigratedValues(_ settings: [String: Any]) -> [String: NSNumber] {
        let wasPrivate = UserDefaults.userDefaultsPrivate()
        // The in-memory private store is lazily allocated by +privateUserDefaults; the read/write
        // paths reference that static directly, so it must be initialized BEFORE enabling private
        // mode or every write is a no-op and every read returns nil (see the identical reference in
        // -[SEBConfigFileManager storeDecryptedSEBSettings:...]). Keep a strong reference for the
        // duration so the writes land where we read them.
        let privatePreferences = UserDefaults.privateUserDefaults()
        privatePreferences?.removeAllObjects() // clean slate so each import is independent
        UserDefaults.setUserDefaultsPrivate(true)
        defer { UserDefaults.setUserDefaultsPrivate(wasPrivate) }

        let preferences = UserDefaults.standard
        let configFileManager = SEBConfigFileManager()
        configFileManager.store(intoUserDefaults: settings)

        let policy = preferences.secureInteger(forKey: "org_safeexambrowser_SEB_lockdownModePolicy")
        let allowOpenAndSavePanel = preferences.secureBool(forKey: "org_safeexambrowser_SEB_allowOpenAndSavePanel")
        _ = privatePreferences // keep alive until after the reads

        return [
            "lockdownModePolicy": NSNumber(value: policy),
            "allowOpenAndSavePanel": NSNumber(value: allowOpenAndSavePanel),
        ]
    }
}
#endif
