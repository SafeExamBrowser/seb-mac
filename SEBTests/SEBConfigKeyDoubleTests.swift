//
//  SEBConfigKeyDoubleTests.swift
//  SafeExamBrowserTests
//
//  Verifies that floating point values are serialized for the Config Key JSON
//  identically to SEB for Windows (.NET Framework 4.8 Double.ToString with
//  invariant culture, i.e. the "G15" general format: up to 15 significant
//  digits). See seb-win-refactoring issue #1495.
//

import Testing
import Foundation

struct SEBConfigKeyDoubleTests {

    private func jsonString(_ value: Double) -> String {
        SEBCryptor.sharedSEBCryptor().jsonString(forObject: NSNumber(value: value))
    }

    // The value from the field-reported mismatch (issue #1495): Windows emits
    // "1.23456789012346" (15 significant digits), macOS previously emitted the
    // shortest round-tripping form "1.234567890123457" (16 digits).
    @Test func reportedMismatchValueMatchesWindows() {
        #expect(jsonString(1.2345678901234567) == "1.23456789012346")
    }

    // Classic binary rounding artifact: must collapse to "0.3", not
    // "0.30000000000000004".
    @Test func roundingArtifactCollapsesTo15Digits() {
        #expect(jsonString(0.1 + 0.2) == "0.3")
        #expect(jsonString(1.0 / 3.0) == "0.333333333333333")
    }

    // "Nice" values used by the actual floating point settings
    // (screenProctoringImageDownscale, batteryChargeThreshold*, default*ZoomLevel)
    // must be unchanged from before, so existing configs keep matching.
    @Test func niceValuesAreUnchanged() {
        #expect(jsonString(1.0) == "1")
        #expect(jsonString(0.5) == "0.5")
        #expect(jsonString(1.5) == "1.5")
        #expect(jsonString(0.1) == "0.1")
        #expect(jsonString(0.25) == "0.25")
        #expect(jsonString(2.0) == "2")
    }
}
