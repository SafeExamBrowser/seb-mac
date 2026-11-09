//
//  SEBKeychainPasswordHashTests.swift
//  SafeExamBrowserTests
//
//  Verifies that password hashes with accented characters are matched
//  consistently with SEB for Windows and Moodle. Passwords are hashed after
//  normalizing to Unicode NFC (precomposed) form, and the comparison falls back
//  to the non-normalized hash for backward compatibility with hashes generated
//  on Apple platforms before normalization was introduced.
//
//  Uses XCTest rather than the Testing framework because this target's
//  deployment target (macOS 10.13) predates the concurrency runtime the
//  swift-testing macros require (macOS 10.15+).
//

import XCTest
import Safe_Exam_Browser

final class SEBKeychainPasswordHashTests: XCTestCase {

    // "café" with the accented "e" as a single precomposed code point (NFC),
    // the form produced by Windows/.NET and by Moodle's web backend.
    private let passwordNFC = "caf\u{00E9}"
    // The same password with the accent as a combining mark (NFD), the form
    // text input on Apple platforms often produces.
    private let passwordNFD = "cafe\u{0301}"

    private func hash(_ s: String) -> String {
        SEBKeychainManagerTestSupport.hash(s)
    }
    private func rawHash(_ s: String) -> String {
        SEBKeychainManagerTestSupport.hashWithoutNormalization(s)
    }
    private func matches(_ hashedString: String, _ password: String) -> Bool {
        SEBKeychainManagerTestSupport.hashedString(hashedString, matchesPassword: password)
    }

    // Guard: the two forms really are different byte sequences, otherwise the
    // rest of these tests would be vacuously true. (Note Swift's String == uses
    // Unicode canonical equivalence, so the two are considered equal as Strings;
    // the difference only shows at the UTF-8 byte / hash level, which is exactly
    // what caused the cross-platform mismatch.)
    func testNFCandNFDareDistinctInputs() {
        XCTAssertNotEqual(Array(passwordNFC.utf8), Array(passwordNFD.utf8))
        XCTAssertNotEqual(rawHash(passwordNFC), rawHash(passwordNFD))
    }

    // Normalization unifies the two forms to the same (NFC) hash, which equals
    // the raw hash of the NFC bytes (what Windows/Moodle store).
    func testNormalizedHashIsFormIndependent() {
        XCTAssertEqual(hash(passwordNFC), hash(passwordNFD))
        XCTAssertEqual(hash(passwordNFD), rawHash(passwordNFC))
    }

    // The reported bug: a hash created by Moodle/Windows (NFC) must be matched
    // by a password entered in NFD form on an Apple platform.
    func testNFDEnteredPasswordMatchesWindowsNFCHash() {
        let storedHash = rawHash(passwordNFC)   // as stored by Moodle/Windows
        XCTAssertTrue(matches(storedHash, passwordNFD))
        XCTAssertTrue(matches(storedHash, passwordNFC))
    }

    // Backward-compatibility fallback: a hash previously generated on an Apple
    // platform from NFD input (before normalization) must still be matched when
    // the password is entered again in the same NFD form.
    func testLegacyNFDHashStillMatchesViaFallback() {
        let legacyStoredHash = rawHash(passwordNFD)   // as stored by old Apple SEB
        XCTAssertTrue(matches(legacyStoredHash, passwordNFD))
        // The primary (normalized) comparison alone would not match this hash.
        XCTAssertNotEqual(hash(passwordNFD), legacyStoredHash)
    }

    // Stored hashes are compared case-insensitively (SEB uppercases them in some
    // code paths), so an uppercase stored hash must still match.
    func testComparisonIsCaseInsensitive() {
        XCTAssertTrue(matches(rawHash(passwordNFC).uppercased(), passwordNFD))
    }

    // A wrong password must never match.
    func testWrongPasswordDoesNotMatch() {
        let storedHash = rawHash(passwordNFC)
        XCTAssertFalse(matches(storedHash, "wrong"))
        XCTAssertFalse(matches(storedHash, "caf"))
    }

    // ASCII passwords are unaffected: the NFC and raw hashes are identical.
    func testASCIIPasswordUnaffected() {
        let ascii = "Secret123"
        XCTAssertEqual(hash(ascii), rawHash(ascii))
        XCTAssertTrue(matches(rawHash(ascii), ascii))
    }
}
