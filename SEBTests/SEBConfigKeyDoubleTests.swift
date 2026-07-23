//
//  SEBConfigKeyDoubleTests.swift
//  SafeExamBrowserTests
//
//  Verifies that floating point values are serialized for the Config Key JSON
//  identically to SEB for Windows (.NET Framework 4.8 Double.ToString with
//  invariant culture, i.e. the "G15" general format: up to 15 significant
//  digits). See seb-win-refactoring issue #1495.
//
//  Uses XCTest rather than the Testing framework because this target's
//  deployment target (macOS 10.13) predates the concurrency runtime the
//  swift-testing macros require (macOS 10.15+).
//

import XCTest
import Safe_Exam_Browser

final class SEBConfigKeyDoubleTests: XCTestCase {

    private func jsonString(_ value: Double) -> String {
        SEBCryptorConfigKeyTestSupport.jsonString(forDouble: value)
    }

    // The value from the field-reported mismatch (issue #1495): Windows emits
    // "1.23456789012346" (15 significant digits), macOS previously emitted the
    // shortest round-tripping form "1.234567890123457" (16 digits).
    func testReportedMismatchValueMatchesWindows() {
        XCTAssertEqual(jsonString(1.2345678901234567), "1.23456789012346")
    }

    // Classic binary rounding artifact: must collapse to "0.3", not
    // "0.30000000000000004".
    func testRoundingArtifactCollapsesTo15Digits() {
        XCTAssertEqual(jsonString(0.1 + 0.2), "0.3")
        XCTAssertEqual(jsonString(1.0 / 3.0), "0.333333333333333")
    }

    // "Nice" values used by the actual floating point settings
    // (screenProctoringImageDownscale, batteryChargeThreshold*, default*ZoomLevel)
    // must be unchanged from before, so existing configs keep matching.
    func testNiceValuesAreUnchanged() {
        XCTAssertEqual(jsonString(1.0), "1")
        XCTAssertEqual(jsonString(0.5), "0.5")
        XCTAssertEqual(jsonString(1.5), "1.5")
        XCTAssertEqual(jsonString(0.1), "0.1")
        XCTAssertEqual(jsonString(0.25), "0.25")
        XCTAssertEqual(jsonString(2.0), "2")
    }

    // .NET Framework 4.8 drops the sign of negative zero ("0"), whereas printf's
    // "%.15g" would emit "-0"; both zeroes must serialize as "0".
    func testNegativeZeroIsNormalized() {
        XCTAssertEqual(jsonString(-0.0), "0")
        XCTAssertEqual(jsonString(0.0), "0")
    }

    // Notation, not just precision: G15 (and %.15g) switch to scientific notation
    // for exponents < -4 or >= 15, using an uppercase 'E'. 0.00001 has exponent -5.
    // (Note this differs from RFC 8785, which would render "0.00001".)
    func testScientificNotationMatchesWindows() {
        XCTAssertEqual(jsonString(0.00001), "1E-05")
        XCTAssertEqual(jsonString(0.0001), "0.0001")   // exponent -4: still fixed-point
    }
}
