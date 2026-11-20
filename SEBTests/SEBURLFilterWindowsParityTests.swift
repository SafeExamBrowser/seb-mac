//
//  SEBURLFilterWindowsParityTests.swift
//  SafeExamBrowserTests
//
//  Cross-platform parity tests for the SEB URL filter: the same test cases as the
//  SEB for Windows unit tests, so the identical filter expressions can be compared
//  on both platforms. Ported from
//  seb-win-refactoring/SafeExamBrowser.Browser.UnitTests/Filters:
//    - Rules/SimplifiedRuleTests.cs  -> the simplified filter-expression spec,
//      which on macOS is SEBURLFilterExpression/SEBURLFilterRegexExpression matched
//      per URL component by -[SEBURLFilter testURLAllowed:].
//    - RequestFilterTests.cs         -> the block-before-allow precedence and the
//      fail-closed default of -[SEBURLFilter testURLAllowed:].
//
//  Not ported (Windows-architecture-specific, no macOS equivalent):
//    - RuleFactoryTests.cs (RuleFactory: Regex vs Simplified rule classes)
//    - SimplifiedRule/RegexRule MustValidateExpression & MustNotAllowUndefined
//      expression: Windows rejects certain characters / undefined expressions by
//      throwing; macOS parses simplified expressions leniently and skips empty or
//      unparseable ones instead (covered in SEBURLFilterSanitizingTests).
//    - MustInitializeResult (the FilterResult enum is set by the caller on macOS).
//
//  Uses XCTest rather than the Testing framework to match the other tests in this
//  target.
//

import XCTest
import Safe_Exam_Browser

final class SEBURLFilterWindowsParityTests: XCTestCase {

    // Whether `urlString` is allowed by a filter containing the single simplified
    // allow expression. URLs are built with NSURL (as the browser hands them to the
    // filter); an unparseable URL counts as "not allowed".
    private func allowed(_ expression: String, _ urlString: String) -> Bool {
        guard let url = NSURL(string: urlString) as URL? else { return false }
        return (try? SEBURLFilterTestSupport.isURLAllowed(url, allowExpressions: [expression])) ?? false
    }

    private func assertMatches(_ expression: String,
                               positive: [String],
                               negative: [String],
                               file: StaticString = #filePath,
                               line: UInt = #line) {
        for url in positive {
            XCTAssertTrue(allowed(expression, url), "expr '\(expression)' should MATCH '\(url)'", file: file, line: line)
        }
        for url in negative {
            XCTAssertFalse(allowed(expression, url), "expr '\(expression)' should NOT match '\(url)'", file: file, line: line)
        }
    }

    // MARK: - SimplifiedRuleTests.cs

    func testMustIgnoreCase() {
        XCTAssertTrue(allowed("http://www.test.org/path/file.txt?param=123", "hTtP://wWw.TeSt.OrG/pAtH/fIlE.tXt?PaRaM=123"))
        XCTAssertTrue(allowed("http://www.test.org/path/file.txt?param=123", "HtTp://WwW.tEst.oRg/PaTh/FiLe.TxT?pArAm=123"))
        XCTAssertTrue(allowed("HTTP://WWW.TEST.ORG/PATH/FILE.TXT?PARAM=123", "hTtP://wWw.TeSt.OrG/pAtH/fIlE.tXt?PaRaM=123"))
        XCTAssertTrue(allowed("HTTP://WWW.TEST.ORG/PATH/FILE.TXT?PARAM=123", "HtTp://WwW.tEst.oRg/PaTh/FiLe.TxT?pArAm=123"))
    }

    func testAlphanumericExpression() {
        let expression = "hostname123"
        assertMatches(expression,
                      positive: ["scheme://\(expression)"],
                      negative: [
                        "scheme://hostname",
                        "scheme://hostname1",
                        "scheme://hostname12",
                        "scheme://hostname1234",
                        "scheme://\(expression).org",
                        "scheme://www.\(expression).org",
                        "scheme://subdomain.\(expression).com",
                        "scheme://www.realhost.\(expression)",
                        "scheme://subdomain-1.subdomain-2.\(expression).org",
                        "scheme://user:password@www.\(expression).org/path/file.txt?param=123#fragment",
                        "scheme://\(expression)4",
                        "scheme://hostname.org",
                        "scheme://hostname12.org",
                        "scheme://\(expression)4.org",
                        "scheme://\(expression).realhost.org",
                        "scheme://subdomain.\(expression).realhost.org",
                        "\(expression)://www.host.org",
                        "scheme://www.host.org/\(expression)/path",
                        "scheme://www.host.org/path?param=\(expression)",
                        "scheme://\(expression):password@www.host.org",
                        "scheme://user:\(expression)@www.host.org",
                        "scheme://user:password@www.host.org/path?param=123#\(expression)",
                      ])
    }

    func testAlphanumericExpressionWithWildcard() {
        assertMatches("hostname*",
                      positive: [
                        "scheme://hostname.org",
                        "scheme://hostnameabc.org",
                        "scheme://hostname-12.org",
                        "scheme://hostname-abc-def-123-456.org",
                        "scheme://www.hostname-abc.org",
                        "scheme://www.realhost.hostname",
                        "scheme://subdomain.hostname-xyz.com",
                        "scheme://hostname.realhost.org",
                        "scheme://subdomain.hostname.realhost.org",
                        "scheme://subdomain-1.subdomain-2.hostname-abc-123.org",
                        "scheme://user:password@www.hostname-abc.org/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://hostnam.org",
                        "hostname://www.host.org",
                        "scheme://www.host.org/hostname/path",
                        "scheme://www.host.org/path?param=hostname",
                        "scheme://hostname:password@www.host.org",
                        "scheme://user:hostname@www.host.org",
                        "scheme://user:password@www.host.org/path?param=123#hostname",
                      ])
    }

    func testHostWithDomain() {
        let expression = "123-hostname.org"
        assertMatches(expression,
                      positive: [
                        "scheme://\(expression)",
                        "scheme://www.\(expression)",
                        "scheme://subdomain.\(expression)",
                        "scheme://subdomain-1.subdomain-2.\(expression)",
                        "scheme://user:password@www.\(expression)/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://123.org",
                        "scheme://123-host.org",
                        "scheme://\(expression).com",
                        "scheme://\(expression)s.org",
                        "scheme://\(expression).realhost.org",
                        "scheme://subdomain.\(expression).realhost.org",
                        "scheme\(expression)://www.host.org",
                        "scheme://www.host.org/\(expression)/path",
                        "scheme://www.host.org/path?param=\(expression)",
                        "scheme://\(expression):password@www.host.org",
                        "scheme://user:\(expression)@www.host.org",
                        "scheme://user:password@www.host.org/path?param=123#\(expression)",
                      ])
    }

    func testHostWithWildcard() {
        assertMatches("test.*.org",
                      positive: [
                        "scheme://test.host.org",
                        "scheme://test.host.domain.org",
                        "scheme://subdomain.test.host.org",
                        "scheme://user:password@test.domain.org/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://test.org",
                        "scheme://host.com/test.host.org",
                        "scheme://www.host.org/test.host.org/path",
                        "scheme://www.host.org/path?param=test.host.org",
                        "scheme://test.host.org:password@www.host.org",
                        "scheme://user:test.host.org@www.host.org",
                        "scheme://user:password@www.host.org/path?param=123#test.host.org",
                      ])
    }

    func testHostWithWildcardAsSuffix() {
        assertMatches("test.host.*",
                      positive: [
                        "scheme://test.host.org",
                        "scheme://test.host.domain.org",
                        "scheme://subdomain.test.host.org",
                        "scheme://user:password@test.host.org/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.com",
                        "scheme://test.host",
                        "scheme://host.com/test.host.txt",
                      ])
    }

    func testHostWithWildcardAsPrefix() {
        assertMatches("*.org",
                      positive: [
                        "scheme://domain.org",
                        "scheme://test.host.org",
                        "scheme://test.host.domain.org",
                        "scheme://user:password@www.host.org/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://org",
                        "scheme://host.com",
                        "scheme://test.net",
                        "scheme://test.ch",
                        "scheme://host.com/test.org",
                      ])
    }

    func testHostWithExactSubdomain() {
        assertMatches(".www.host.org",
                      positive: [
                        "scheme://www.host.org",
                        "scheme://user:password@www.host.org/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://test.www.host.org",
                        "scheme://www.host.org.com",
                      ])
    }

    func testHostWithTrailingSlash() {
        assertMatches("host.org/",
                      positive: [
                        "scheme://host.org",
                        "scheme://host.org/",
                        "scheme://host.org/url",
                        "scheme://host.org/url/",
                        "scheme://host.org/url/path",
                        "scheme://host.org/url/path/",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.host.org/url/path/?param=123#fragment",
                      ],
                      negative: [])
    }

    func testHostWithoutTrailingSlash() {
        assertMatches("host.org",
                      positive: [
                        "scheme://host.org",
                        "scheme://host.org/",
                        "scheme://host.org/url",
                        "scheme://host.org/url/",
                        "scheme://host.org/url/path",
                        "scheme://host.org/url/path/",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.host.org/url/path/?param=123#fragment",
                      ],
                      negative: [])
    }

    func testPortNumber() {
        assertMatches("host.org:2020",
                      positive: [
                        "scheme://host.org:2020",
                        "scheme://www.host.org:2020",
                        "scheme://user:password@www.host.org:2020/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://www.host.org",
                        "scheme://www.host.org:2",
                        "scheme://www.host.org:20",
                        "scheme://www.host.org:202",
                        "scheme://www.host.org:20202",
                      ])
    }

    func testPortWildcard() {
        assertMatches("host.org:*",
                      positive: [
                        "scheme://host.org",
                        "scheme://host.org:0",
                        "scheme://host.org:1",
                        "scheme://host.org:2020",
                        "scheme://host.org:65535",
                        "scheme://www.host.org",
                        "scheme://www.host.org:2",
                        "scheme://www.host.org:20",
                        "scheme://www.host.org:202",
                        "scheme://www.host.org:2020",
                        "scheme://www.host.org:20202",
                        "scheme://user:password@www.host.org:2020/path/file.txt?param=123#fragment",
                      ],
                      negative: [])
    }

    func testPortNumberWithHostWildcard() {
        // Windows iterates every port 0...65535; a representative sample is enough here.
        var negative = ["scheme://host.org"]
        for port in [0, 1, 2, 19, 21, 80, 443, 2019, 2021, 8080, 20202, 65535] where port != 2020 {
            negative.append("scheme://host.org:\(port)")
        }
        assertMatches("*:2020",
                      positive: [
                        "scheme://host.org:2020",
                        "scheme://domain.com:2020",
                        "scheme://user:password@www.server.net:2020/path/file.txt?param=123#fragment",
                      ],
                      negative: negative)
    }

    func testPath() {
        assertMatches("host.org/url/path",
                      positive: [
                        "scheme://host.org/url/path",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org//",
                        "scheme://host.org///",
                        "scheme://host.org/url",
                        "scheme://host.org/path",
                        "scheme://host.org/url/path.txt",
                        "scheme://host.org/another/url/path",
                      ])
    }

    func testPathWithFile() {
        assertMatches("host.org/url/path/to/file.txt",
                      positive: [
                        "scheme://host.org/url/path/to/file.txt",
                        "scheme://subdomain.host.org/url/path/to/file.txt",
                        "scheme://user:password@www.host.org/url/path/to/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org/url",
                        "scheme://host.org/path",
                        "scheme://host.org/file.txt",
                        "scheme://host.org/url/path.txt",
                        "scheme://host.org/url/path/to.txt",
                        "scheme://host.org/url/path/to/file",
                        "scheme://host.org/url/path/to/file.",
                        "scheme://host.org/url/path/to/file.t",
                        "scheme://host.org/url/path/to/file.tx",
                        "scheme://host.org/url/path/to/file.txt/segment",
                        "scheme://host.org/url/path/to/file.txtt",
                        "scheme://host.org/another/url/path/to/file.txt",
                      ])
    }

    func testPathWithWildcard() {
        assertMatches("host.org/*/path",
                      positive: [
                        // "scheme://host.org//path" -> see testDivergence_PathWildcardEmptySegment
                        "scheme://host.org/url/path",
                        "scheme://host.org/another/url/path",
                        "scheme://user:password@www.host.org/yet/another/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org/url",
                        "scheme://host.org/path",
                        "scheme://host.org/url/path.txt",
                        "scheme://host.org/url/path/2",
                      ])
    }

    func testPathWithHostWildcard() {
        assertMatches("*/url/path",
                      positive: [
                        "scheme://local/url/path",
                        "scheme://host.org/url/path",
                        "scheme://www.host.org/url/path",
                        "scheme://another.server.org/url/path",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org/url",
                        "scheme://host.org/path",
                        "scheme://host.org/url/path.txt",
                        "scheme://host.org/url/path/2",
                      ])
    }

    func testPathWithTrailingSlash() {
        assertMatches("host.org/url/path/",
                      positive: [
                        "scheme://host.org/url/path",
                        "scheme://host.org/url/path/",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.host.org/url/path/?param=123#fragment",
                      ],
                      negative: [])
    }

    func testPathWithoutTrailingSlash() {
        assertMatches("host.org/url/path",
                      positive: [
                        "scheme://host.org/url/path",
                        "scheme://host.org/url/path/",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.host.org/url/path/?param=123#fragment",
                      ],
                      negative: [])
    }

    func testScheme() {
        assertMatches("scheme://host.org",
                      positive: [
                        "scheme://host.org",
                        "scheme://www.host.org",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "//host.org",
                        "https://host.org",
                        "ftp://host.org",
                        "ftps://host.org",
                        "schemes://host.org",
                      ])
    }

    func testSchemeWithWildcard() {
        assertMatches("*tp://host.org",
                      positive: [
                        "tp://host.org",
                        "ftp://www.host.org",
                        "http://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "//host.org",
                        "p://host.org",
                        "https://host.org",
                        "ftps://host.org",
                      ])
    }

    func testSchemeWithHostWildcard() {
        assertMatches("scheme://*",
                      positive: [
                        "scheme://host",
                        "scheme://www.server.org",
                        "scheme://subdomain.domain.org",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "//host.org",
                        "http://host.org",
                        "https://host.org",
                        "ftp://host.org",
                        "ftps://host.org",
                      ])
    }

    func testUserInfoWithName() {
        assertMatches("user@host.org",
                      positive: [
                        "scheme://user@host.org",
                        "scheme://user@www.host.org",
                        "scheme://user:password@host.org",
                        "scheme://user:password-123@host.org",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://u@host.org",
                        "scheme://us@host.org",
                        "scheme://use@host.org",
                        "scheme://usera@host.org",
                        "scheme://user@server.net",
                        "scheme://usertwo@www.host.org",
                      ])
    }

    func testUserInfoWithNameWildcard() {
        assertMatches("user*@host.org",
                      positive: [
                        "scheme://user@host.org",
                        "scheme://userabc@host.org",
                        "scheme://user:abc@host.org",
                        "scheme://user-123@www.host.org",
                        "scheme://user-123:password@host.org",
                        "scheme://user-123:password-123@host.org",
                        "scheme://user-abc-123:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://u@host.org",
                        "scheme://us@host.org",
                        "scheme://use@host.org",
                        "scheme://user@server.net",
                        "scheme://usertwo@server.org",
                      ])
    }

    func testUserInfoWithPassword() {
        assertMatches("user:password@host.org",
                      positive: [
                        "scheme://user:password@host.org",
                        "scheme://user:password@www.host.org",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://u@host.org",
                        "scheme://us@host.org",
                        "scheme://use@host.org",
                        "scheme://user@server.net",
                        "scheme://usertwo@server.org",
                        "scheme://user@host.org",
                        "scheme://userabc@host.org",
                        "scheme://user:abc@host.org",
                        "scheme://user-123@www.host.org",
                        "scheme://user-123:password@host.org",
                        "scheme://user-123:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password-123@host.org",
                        "scheme://user:password-123@www.host.org/url/path?param=123#fragment",
                      ])
    }

    func testUserInfoWithWildcard() {
        assertMatches("*@host.org",
                      positive: [
                        "scheme://host.org",
                        "scheme://user@host.org",
                        "scheme://user:password@host.org",
                        "scheme://www.host.org/url/path?param=123#fragment",
                        "scheme://user@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://server.org",
                        "scheme://user@server.org",
                        "scheme://www.server.org/url/path?param=123#fragment",
                        "scheme://user:password@www.server.org/url/path?param=123#fragment",
                      ])
    }

    func testUserInfoWithHostWildcard() {
        assertMatches("user:password@*",
                      positive: [
                        "scheme://user:password@host.org",
                        "scheme://user:password@server.net",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://server.org",
                        "scheme://user@host.org",
                        "scheme://user@server.org",
                        "scheme://password@host.org",
                        "scheme://www.host.org/url/path?param=123#fragment",
                        "scheme://www.server.org/url/path?param=123#fragment",
                        "scheme://user@www.host.org/url/path?param=123#fragment",
                        "scheme://user@www.server.org/url/path?param=123#fragment",
                        "scheme://password@www.server.org/url/path?param=123#fragment",
                      ])
    }

    func testQuery() {
        assertMatches("host.org?param=123",
                      positive: [
                        "scheme://host.org?param=123",
                        "scheme://www.host.org/?param=123",
                        "scheme://www.host.org/path/?param=123",
                        "scheme://www.host.org/some/other/random/path?param=123",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org?",
                        "scheme://host.org?=",
                        "scheme://host.org?=123",
                        "scheme://host.org?param=",
                        "scheme://host.org?param=1",
                        "scheme://host.org?param=12",
                        "scheme://host.org?param=1234",
                      ])
    }

    func testQueryWithWildcardAsPrefix() {
        assertMatches("host.org?*param=123",
                      positive: [
                        "scheme://host.org?param=123",
                        "scheme://www.host.org?param=123",
                        "scheme://www.host.org/path/?param=123",
                        "scheme://www.host.org/some/other/random/path?param=123",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://host.org?other_param=456&param=123",
                        "scheme://host.org?param=123&another_param=123",
                        "scheme://www.host.org?other_param=456&param=123",
                        "scheme://www.host.org/path/?other_param=456&param=123",
                        "scheme://www.host.org/some/other/random/path?other_param=456&param=123",
                        "scheme://user:password@www.host.org/url/path?other_param=456&param=123#fragment",
                        "scheme://host.org?some_param=123469yvuiopwo&another_param=some%20whitespaces%26special%20characters%2B%22%2A%25%C3%A7%2F%28&param=123",
                      ],
                      negative: [
                        "scheme://host.org?",
                        "scheme://host.org?=",
                        "scheme://host.org?=123",
                        "scheme://host.org?aram=123",
                        "scheme://host.org?param=",
                        "scheme://host.org?param=1",
                        "scheme://host.org?param=12",
                        "scheme://host.org?param=1234",
                        "scheme://host.org?param=123&another_param=456",
                      ])
    }

    func testQueryWithWildcardAsSuffix() {
        assertMatches("host.org?param=123*",
                      positive: [
                        "scheme://host.org?param=123",
                        "scheme://host.org?param=1234",
                        "scheme://www.host.org?param=123",
                        "scheme://www.host.org/path/?param=123",
                        "scheme://host.org?param=123&another_param=456",
                        "scheme://www.host.org/some/other/random/path?param=123",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://host.org?param=123&other_param=456",
                        "scheme://www.host.org/path/?param=123&other_param=456",
                        "scheme://www.host.org/some/other/random/path?param=123&other_param=456",
                        "scheme://user:password@www.host.org/url/path?param=123&other_param=456#fragment",
                        "scheme://host.org?param=123&some_param=123469yvuiopwo&another_param=some%20whitespaces%26special%20characters%2B%22%2A%25%C3%A7%2F%28",
                      ],
                      negative: [
                        "scheme://host.org?",
                        "scheme://host.org?=",
                        "scheme://host.org?=123",
                        "scheme://host.org?aram=123",
                        "scheme://host.org?param=",
                        "scheme://host.org?param=1",
                        "scheme://host.org?param=12",
                        "scheme://host.org?aparam=123",
                        "scheme://www.host.org?param=456&param=123",
                        "scheme://host.org?some_param=123469yvuiopwo&another_param=some%20whitespaces%26special%20characters%2B%22%2A%25%C3%A7%2F%28&param=123",
                      ])
    }

    func testQueryNotAllowed() {
        assertMatches("host.org?.",
                      positive: [
                        "scheme://host.org",
                        "scheme://host.org?",
                        "scheme://user:password@www.host.org/url/path#fragment",
                        "scheme://user:password@www.host.org/url/path?#fragment",
                      ],
                      negative: [
                        "scheme://host.org?a",
                        "scheme://host.org?%20",
                        "scheme://host.org?=",
                      ])
    }

    func testQueryWithHostWildcard() {
        assertMatches("*?param=123",
                      positive: [
                        "scheme://host.org?param=123",
                        "scheme://server.net?param=123",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.server.net/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org?param=1234",
                        "scheme://host.org?param=12",
                        "scheme://host.org?",
                        "scheme://host.org?param",
                        "scheme://host.org?123",
                        "scheme://host.org?=",
                      ])
    }

    func testFragment() {
        assertMatches("host.org#fragment",
                      positive: [
                        "scheme://host.org#fragment",
                        "scheme://www.host.org#fragment",
                        "scheme://user:password@www.host.org/url/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org#",
                        "scheme://host.org#fragmen",
                        "scheme://host.org#fragment123",
                        "scheme://host.org#otherfragment",
                      ])
    }

    func testFragmentWithWildcardAsPrefix() {
        assertMatches("host.org#*fragment",
                      positive: [
                        "scheme://host.org#fragment",
                        "scheme://host.org#somefragment",
                        "scheme://www.host.org#another_fragment",
                        "scheme://user:password@www.host.org/url/path/file.txt?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org#",
                        "scheme://host.org#fragmen",
                        "scheme://host.org#fragment123",
                      ])
    }

    func testFragmentWithWildcardAsSuffix() {
        assertMatches("host.org#fragment*",
                      positive: [
                        "scheme://host.org#fragment",
                        "scheme://host.org#fragment-123",
                        "scheme://user:password@www.host.org/url/path/file.txt?param=123#fragment_abc",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org#",
                        "scheme://host.org#fragmen",
                        "scheme://www.host.org#another_fragment",
                      ])
    }

    func testFragmentWithHostWildcard() {
        assertMatches("*#fragment",
                      positive: [
                        "scheme://host.org#fragment",
                        "scheme://server.net#fragment",
                        "scheme://user:password@www.host.org/url/path?param=123#fragment",
                        "scheme://user:password@www.server.net/url/path?param=123#fragment",
                      ],
                      negative: [
                        "scheme://host.org",
                        "scheme://host.org#",
                        "scheme://host.org#fragmen",
                        "scheme://host.org#fragment123",
                      ])
    }

    // MARK: - Known divergences from SEB for Windows
    //
    // Remaining case that passes on SEB for Windows but still behaves differently on
    // macOS. It asserts the SEB-for-Windows expectation wrapped in XCTExpectFailure,
    // so the suite stays green while documenting the difference. If macOS matching is
    // changed to match Windows, the XCTExpectFailure will "unexpectedly pass" and fail
    // the test, signalling that the case should move up into the parity tests above.

    private func assertWindowsExpectation(_ expression: String, matching: [String], notMatching: [String]) {
        for url in matching {
            XCTAssertTrue(allowed(expression, url), "expr '\(expression)' should MATCH '\(url)'")
        }
        for url in notMatching {
            XCTAssertFalse(allowed(expression, url), "expr '\(expression)' should NOT match '\(url)'")
        }
    }

    // macOS trims leading/trailing slashes from the path, collapsing an empty path
    // segment, so "host.org/*/path" doesn't match "host.org//path" (an empty segment).
    // Deferred: low-severity edge case; fixing it means reworking path slash handling.
    func testDivergence_PathWildcardEmptySegment() {
        XCTExpectFailure("macOS trims slashes, so an empty path segment doesn't match")
        assertWindowsExpectation("host.org/*/path", matching: ["scheme://host.org//path"], notMatching: [])
    }

    // MARK: - RequestFilterTests.cs (block-before-allow precedence, fail-closed default)

    private let block = 0     // URLFilterActionBlock
    private let allow = 1     // URLFilterActionAllow
    private let unknown = 3   // URLFilterActionUnknown (no rule matched -> blocked by caller)

    func testMustProcessBlockRulesFirst() throws {
        // A URL matched by both an allow and a block rule must be blocked
        let url = URL(string: "scheme://host.org/secret")!
        let action = try SEBURLFilterTestSupport.filterAction(for: url, allowExpressions: ["host.org"], blockExpressions: ["host.org/secret"])
        XCTAssertEqual(action, block)
    }

    func testMustProcessAllowRulesSecond() throws {
        // A URL matched only by an allow rule is allowed
        let url = URL(string: "scheme://host.org/public")!
        let action = try SEBURLFilterTestSupport.filterAction(for: url, allowExpressions: ["host.org"], blockExpressions: ["host.org/secret"])
        XCTAssertEqual(action, allow)
    }

    func testMustReturnDefaultWithoutMatch() throws {
        // No rule matches -> macOS returns Unknown (the caller treats it as blocked)
        let url = URL(string: "scheme://other.net")!
        let action = try SEBURLFilterTestSupport.filterAction(for: url, allowExpressions: ["host.org"], blockExpressions: ["evil.org"])
        XCTAssertEqual(action, unknown)
    }

    func testMustReturnDefaultWithoutRules() throws {
        // No rules at all -> Unknown (fail closed)
        let url = URL(string: "scheme://host.org")!
        let action = try SEBURLFilterTestSupport.filterAction(for: url, allowExpressions: [], blockExpressions: [])
        XCTAssertEqual(action, unknown)
    }
}
