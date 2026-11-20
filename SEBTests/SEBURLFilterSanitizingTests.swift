//
//  SEBURLFilterSanitizingTests.swift
//  SafeExamBrowserTests
//
//  Verifies that URL filter expressions are sanitized: empty, whitespace-only
//  or unparseable expressions must not create filter expressions (which would
//  match every URL), invalid regexes must be reported as an error instead of
//  crashing, and the regexes used for the WKContentRuleList must be anchored
//  to the scheme/host of the expression.
//
//  Uses XCTest rather than the Testing framework because this target's
//  deployment target predates the concurrency runtime the swift-testing
//  macros require.
//

import XCTest
import Safe_Exam_Browser

final class SEBURLFilterSanitizingTests: XCTestCase {

    private let examURL = URL(string: "https://exam.example.org/quiz/attempt.php?id=42")!

    private func matches(_ pattern: String, _ urlString: String) throws -> Bool {
        let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .anchorsMatchLines])
        return regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) != nil
    }

    // MARK: - Empty / unparseable expressions

    func testEmptyAndWhitespaceExpressionsCreateNoFilterExpressions() throws {
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: ""), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "   "), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "\n\t"), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "", regex: true), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "  ", regex: true), 0)
    }

    func testNonStringExpressionCreatesNoFilterExpressions() throws {
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: NSNumber(value: 1)), 0)
    }

    func testMalformedExpressionDoesNotMatchUnrelatedURLs() throws {
        // The simplified-expression splitter is permissive (like SEB for Windows): a
        // malformed expression is split into whatever components it yields rather than
        // rejected. The safety property is that it must not turn into a match-everything
        // rule — it only matches its (garbage) components, not unrelated URLs.
        XCTAssertFalse(try SEBURLFilterTestSupport.isURLAllowed(examURL, allowExpressions: ["http://[::1"]))
    }

    func testDelimiterOnlyExpressionCreatesNoFilterExpressions() throws {
        // Strings consisting only of component delimiters split into all-empty
        // components, which must not create a (match-everything) filter expression.
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "://"), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "@"), 0)
    }

    func testValidExpressionsStillCreateFilterExpressions() throws {
        XCTAssertGreaterThan(try SEBURLFilterTestSupport.expressionCount(for: "example.org"), 0)
        XCTAssertGreaterThan(try SEBURLFilterTestSupport.expressionCount(for: "  example.org  "), 0)
        XCTAssertGreaterThan(try SEBURLFilterTestSupport.expressionCount(for: "*"), 0)
        XCTAssertGreaterThan(try SEBURLFilterTestSupport.expressionCount(for: "about:blank"), 0)
        XCTAssertEqual(try SEBURLFilterTestSupport.expressionCount(for: "^https://example\\.org/.*$", regex: true), 1)
    }

    func testEmptyAllowRuleDoesNotAllowEveryURL() throws {
        XCTAssertFalse(try SEBURLFilterTestSupport.isURLAllowed(examURL, allowExpressions: ["", "  "]))
        XCTAssertTrue(try SEBURLFilterTestSupport.isURLAllowed(examURL, allowExpressions: ["", "example.org"]))
    }

    func testEmptyIgnoreListEntryDoesNotIgnoreEveryURL() throws {
        XCTAssertFalse(try SEBURLFilterTestSupport.isURLIgnored(examURL, ignoreEntries: [""]))
        XCTAssertFalse(try SEBURLFilterTestSupport.isURLIgnored(examURL, ignoreEntries: ["   ", NSNumber(value: 0)]))
        XCTAssertTrue(try SEBURLFilterTestSupport.isURLIgnored(examURL, ignoreEntries: ["", "exam.example.org"]))
    }

    // MARK: - Invalid regex

    func testInvalidRegexThrowsInsteadOfCrashing() {
        XCTAssertThrowsError(try SEBURLFilterTestSupport.expressionCount(for: "([", regex: true))
    }

    // MARK: - Rule list robustness (one bad rule must not discard the whole filter)

    private func allowRule(_ expression: String, regex: Bool = false) -> [String: Any] {
        ["active": true, "regex": regex, "action": URLFilterActionAllow, "expression": expression]
    }

    func testInvalidRegexRuleIsSkippedButOtherRulesKept() {
        let rules: [Any] = [allowRule("([", regex: true), allowRule("example.org")]
        let result = SEBURLFilterTestSupport.processRules(rules)
        XCTAssertTrue(result.hadError)                 // the invalid regex is reported
        XCTAssertGreaterThan(result.allowCount, 0)     // but the valid rule still applies
    }

    func testInactiveAndEmptyRulesAreIgnoredWithoutError() {
        let rules: [Any] = [
            ["active": false, "regex": false, "action": URLFilterActionAllow, "expression": "([", "comment": "inactive invalid regex"] as [String: Any],
            allowRule("   "),          // whitespace-only: skipped, no error
            allowRule("example.org"),
        ]
        let result = SEBURLFilterTestSupport.processRules(rules)
        XCTAssertFalse(result.hadError)
        XCTAssertGreaterThan(result.allowCount, 0)
    }

    // MARK: - Rule list type safety (settings could contain anything)

    func testMalformedRuleEntriesDontCrash() {
        let rules: [Any] = [
            "not a dictionary",
            NSNumber(value: 42),
            ["active": true, "regex": false, "action": URLFilterActionAllow, "expression": NSNumber(value: 1)] as [String: Any], // non-string expression
            allowRule("example.org"),
        ]
        let result = SEBURLFilterTestSupport.processRules(rules)
        XCTAssertFalse(result.hadError)             // non-dictionary / non-string entries are skipped, not errors
        XCTAssertGreaterThan(result.allowCount, 0)  // the one valid rule is still applied
    }

    // MARK: - WKContentRuleList regexes

    func testContentRuleRegexesAreAnchored() throws {
        for expression in ["example.org", "example.org/quiz", "example.org/quiz/*", "example.org/quiz?id=42", "example.org/quiz#top", ".example.org/quiz"] {
            let regexStrings = try SEBURLFilterTestSupport.contentRuleRegexStrings(forAllowExpressions: [expression])
            XCTAssertFalse(regexStrings.isEmpty, expression)
            for regexString in regexStrings {
                XCTAssertTrue(regexString.hasPrefix("^"), "\(expression): \(regexString)")
                XCTAssertTrue(regexString.hasSuffix("$"), "\(expression): \(regexString)")
                XCTAssertFalse(regexString.isEmpty, expression)
            }
        }
    }

    func testContentRuleRegexesDontAllowPathOnOtherHosts() throws {
        let regexStrings = try SEBURLFilterTestSupport.contentRuleRegexStrings(forAllowExpressions: ["example.org/quiz"])
        // None of the content rule regexes may match the allowed path on a foreign
        // host, including when the allowed host/path appears elsewhere in the URL
        // (wildcards must not match across the "://" and "/" component delimiters).
        let foreignURLs = ["https://evil.test/quiz",
                           "https://evil.test/quiz?x=1",
                           "https://evil.test/example.org/quiz",
                           "https://evil.test/?u=https://example.org/quiz",
                           "https://example.org.evil.test/quiz"]
        for regexString in regexStrings {
            for url in foreignURLs {
                XCTAssertFalse(try matches(regexString, url), "\(url) matched \(regexString)")
            }
        }
    }

    func testContentRuleSubdomainWildcardDoesNotCrossSlash() throws {
        let regexStrings = try SEBURLFilterTestSupport.contentRuleRegexStrings(forAllowExpressions: ["*.example.org"])
        XCTAssertTrue(try regexStrings.contains { try matches($0, "https://a.b.example.org/x") })
        for regexString in regexStrings {
            XCTAssertFalse(try matches(regexString, "https://evil.test/a.example.org/"), regexString)
        }
    }

    func testContentRuleRegexesStillAllowIntendedURLs() throws {
        let regexStrings = try SEBURLFilterTestSupport.contentRuleRegexStrings(forAllowExpressions: ["example.org/quiz"])
        for urlString in ["https://example.org/quiz", "https://www.example.org/quiz", "https://example.org/quiz?id=42"] {
            XCTAssertTrue(try regexStrings.contains { try matches($0, urlString) }, urlString)
        }
        let hostRegexStrings = try SEBURLFilterTestSupport.contentRuleRegexStrings(forAllowExpressions: ["example.org"])
        for urlString in ["https://example.org", "https://example.org/any/path", "https://sub.example.org/x?y=1"] {
            XCTAssertTrue(try hostRegexStrings.contains { try matches($0, urlString) }, urlString)
        }
        XCTAssertFalse(try hostRegexStrings.contains { try matches($0, "https://example.org.evil.test/") })
    }
}
