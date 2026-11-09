//
//  SEBKeychainManagerTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge exposing SEBKeychainManager's password hashing and
//  comparison to the Swift unit test target. The test target links the app
//  module but cannot see Objective-C classes like SEBKeychainManager directly,
//  so this small @objc public wrapper (part of the app's Swift module) provides
//  access. Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation

@objc public final class SEBKeychainManagerTestSupport: NSObject {

    private static let keychainManager = SEBKeychainManager()

    /// SHA-256 hash as used for storing and comparing passwords, computed after
    /// normalizing the input to Unicode NFC (consistent with Windows/Moodle).
    @objc public static func hash(_ password: String) -> String {
        return keychainManager.generateSHAHashString(password)
    }

    /// SHA-256 hash of the raw (non-normalized) input, reproducing the behavior
    /// from before NFC normalization was introduced (e.g. an accented password
    /// hashed on macOS/iOS, which was stored in NFD form).
    @objc public static func hashWithoutNormalization(_ password: String) -> String {
        return keychainManager.generateSHAHashStringWithoutNormalization(password)
    }

    /// Whether the entered password matches the stored hash, using the NFC hash
    /// first and the non-normalized hash as a backward-compatibility fallback.
    @objc public static func hashedString(_ hashedString: String, matchesPassword password: String) -> Bool {
        return keychainManager.hashedString(hashedString, matchesPassword: password)
    }
}
#endif
