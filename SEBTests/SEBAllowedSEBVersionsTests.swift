//
//  SEBAllowedSEBVersionsTests.swift
//  SafeExamBrowserTests
//
//  Verifies the parsing and allow/deny decision of SEBAllowedSEBVersions, which
//  backs the sebAllowedVersions configuration key. The class is pure (no user
//  defaults / AppKit), so tests drive it directly through the DEBUG-only
//  SEBAllowedSEBVersionsTestSupport shim.
//
//  Uses XCTest to match the other unit tests in this target.
//

import XCTest
import Safe_Exam_Browser

final class SEBAllowedSEBVersionsTests: XCTestCase {

    // SEBAllowedVersionPlatform raw values
    private let mac = 0
    private let win = 1
    private let ios = 2

    private func allowed(_ version: String,
                         build: String? = nil,
                         platform: Int = 0,
                         ae: Bool = false,
                         _ restrictions: [String]?) -> Bool {
        SEBAllowedSEBVersionsTestSupport.allowed(version: version,
                                                 buildNumber: build,
                                                 platform: platform,
                                                 allianceEdition: ae,
                                                 restrictions: restrictions)
    }

    // MARK: - No restriction

    func testEmptyRestrictions_allowed() {
        XCTAssertTrue(allowed("3.4.0", []))
        XCTAssertTrue(allowed("3.4.0", nil))
    }

    // MARK: - Wrong platform only

    func testOnlyOtherPlatforms_blocked() {
        XCTAssertFalse(allowed("3.4.0", ["Win.3.9.min", "iOS.3.6"]))
    }

    // MARK: - Exact match

    func testExactMatch_specifiedComponentsOnly() {
        XCTAssertTrue(allowed("3.4.0", ["Mac.3.4"]))
        XCTAssertTrue(allowed("3.4.1", ["Mac.3.4"]))   // extra running patch is fine for a 2-component exact rule
        XCTAssertFalse(allowed("3.5.0", ["Mac.3.4"]))
    }

    func testExactMatch_withPatch() {
        XCTAssertTrue(allowed("3.4.1", ["Mac.3.4.1"]))
        XCTAssertFalse(allowed("3.4.0", ["Mac.3.4.1"]))
    }

    // MARK: - Minimum

    func testMinimum_majorMinor() {
        XCTAssertTrue(allowed("3.9.0", ["Mac.3.9.min"]))
        XCTAssertTrue(allowed("4.0.0", ["Mac.3.9.min"]))
        XCTAssertFalse(allowed("3.8.9", ["Mac.3.9.min"]))
    }

    func testMinimum_withPatch() {
        XCTAssertTrue(allowed("3.4.1", ["Mac.3.4.1.min"]))
        XCTAssertFalse(allowed("3.4.0", ["Mac.3.4.1.min"]))
        XCTAssertTrue(allowed("3.5.0", ["Mac.3.4.1.min"]))
    }

    func testMinimum_withBuild() {
        XCTAssertTrue(allowed("3.4.1", build: "1234", ["Mac.3.4.1.1234.min"]))
        XCTAssertTrue(allowed("3.4.1", build: "2000", ["Mac.3.4.1.1234.min"]))
        XCTAssertFalse(allowed("3.4.1", build: "1000", ["Mac.3.4.1.1234.min"]))
    }

    // MARK: - Alliance Edition (this Mac build is never AE)

    func testAllianceEditionEntry_neverSatisfiedByNonAEBuild() {
        XCTAssertFalse(allowed("3.9.0", ae: false, ["Mac.3.9.AE.min"]))
    }

    func testAllianceEditionEntry_siblingNonAEEntryStillAllows() {
        XCTAssertTrue(allowed("3.9.0", ae: false, ["Mac.3.9.AE.min", "Mac.3.4.min"]))
    }

    func testAllianceEditionBuild_matchesAEEntry() {
        XCTAssertTrue(allowed("3.9.0", ae: true, ["Mac.3.9.AE.min"]))
    }

    // MARK: - Mixed lists

    func testMixedList() {
        let list = ["Mac.3.4", "Mac.3.9.min", "Win.3.9.min"]
        XCTAssertTrue(allowed("3.9.0", list))   // satisfies min
        XCTAssertTrue(allowed("3.4.0", list))   // satisfies exact
        XCTAssertFalse(allowed("3.6.0", list))  // neither
    }

    // MARK: - Malformed entries

    func testOnlyEmptyOrMalformedEntries_allowed() {
        // A list of only empty/garbage entries (e.g. an accidental blank row) is
        // treated as "no restriction" rather than blocking.
        XCTAssertTrue(allowed("3.4.0", ["", "Mac", "Mac.x.y", "Mac.3", "Mac.3.4.min.extra"]))
        XCTAssertTrue(allowed("3.4.0", [""]))
        XCTAssertTrue(allowed("3.4.0", ["   "]))
    }

    func testMalformedEntriesMixedWithValidOtherPlatform_blocked() {
        // Garbage is skipped, but a valid non-Mac restriction still blocks the Mac build.
        XCTAssertFalse(allowed("3.4.0", ["", "garbage", "Win.3.9.min"]))
    }

    func testMalformedEntriesSkipped_validEntryStillParsed() {
        XCTAssertTrue(allowed("3.4.0", ["garbage", "Mac.3.4", "Foo.1.2"]))
    }

    func testWhitespaceTrimmed() {
        XCTAssertTrue(allowed("3.9.0", ["  Mac.3.9.min  "]))
    }

    // MARK: - Requirement description

    func testRequirementDescription_nilForEmpty() {
        XCTAssertNil(SEBAllowedSEBVersionsTestSupport.requirementDescription(platform: mac, restrictions: []))
    }

    func testRequirementDescription_min() {
        let text = SEBAllowedSEBVersionsTestSupport.requirementDescription(platform: mac, restrictions: ["Mac.3.9.min"])
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("3.9"))
        XCTAssertTrue(text!.lowercased().contains("higher"))
    }

    func testRequirementDescription_exact() {
        let text = SEBAllowedSEBVersionsTestSupport.requirementDescription(platform: mac, restrictions: ["Mac.3.4", "Mac.3.5.1"])
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("3.4"))
        XCTAssertTrue(text!.contains("3.5.1"))
    }

    func testRequirementDescription_mixed() {
        let text = SEBAllowedSEBVersionsTestSupport.requirementDescription(platform: mac, restrictions: ["Mac.3.9.min", "Mac.3.4"])
        XCTAssertNotNil(text)
        XCTAssertTrue(text!.contains("3.9"))
        XCTAssertTrue(text!.contains("3.4"))
    }
}
