//
//  SEBCryptorConfigKeyTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge that exposes SEBCryptor's private Config Key value
//  serializer to the Swift unit test target. The test target links the app
//  module but cannot see Objective-C classes like SEBCryptor directly, so this
//  small @objc public wrapper (part of the app's Swift module) provides access.
//  Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation

@objc public final class SEBCryptorConfigKeyTestSupport: NSObject {

    /// Serializes a Double exactly as it is included in the Config Key JSON.
    /// See -[SEBCryptor jsonStringForObject:].
    @objc public static func jsonString(forDouble value: Double) -> String {
        return SEBCryptor.shared().jsonString(for: NSNumber(value: value))
    }
}
#endif
