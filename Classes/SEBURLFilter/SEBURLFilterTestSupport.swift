//
//  SEBURLFilterTestSupport.swift
//  SafeExamBrowser
//
//  Test-only bridge that exposes the URL filter expression parsing and matching
//  to the Swift unit test target. The test target links the app module but
//  cannot see Objective-C classes like SEBURLFilter directly, so this small
//  @objc public wrapper (part of the app's Swift module) provides access.
//  Regression coverage for URL filter expression sanitizing (empty/unparseable
//  expressions, invalid regexes, content rule list regex anchoring).
//  Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation

@objc public final class SEBURLFilterTestSupport: NSObject {

    /// Returns the filter expressions created for a URL filter rule expression,
    /// exactly as when loading the URL filter rules from settings.
    /// Throws if the expression is an invalid regex.
    private static func expressions(for expression: Any, regex: Bool) throws -> [Any] {
        return try SEBURLFilter.filterExpressions(forExpressionString: expression, regex: regex)
    }

    /// Number of filter expressions created for a URL filter rule expression
    /// (0 = the rule is skipped). Throws if the expression is an invalid regex.
    public static func expressionCount(for expression: Any, regex: Bool = false) throws -> Int {
        return try expressions(for: expression, regex: regex).count
    }

    /// Regex strings used for the WKContentRuleList allow rules when the passed
    /// expressions are allow rules. See -[SEBURLFilter regexAllowList].
    public static func contentRuleRegexStrings(forAllowExpressions allowExpressions: [String]) throws -> [String] {
        let urlFilter = SEBURLFilter()
        urlFilter.permittedList = NSMutableArray(array: try allowExpressions.flatMap { try expressions(for: $0, regex: false) })
        return urlFilter.regexAllowList
    }

    /// Whether a URL gets allowed by the passed allow expressions.
    /// See -[SEBURLFilter testURLAllowed:].
    public static func isURLAllowed(_ url: URL, allowExpressions: [String]) throws -> Bool {
        let urlFilter = SEBURLFilter()
        urlFilter.prohibitedList = NSMutableArray()
        urlFilter.permittedList = NSMutableArray(array: try allowExpressions.flatMap { try expressions(for: $0, regex: false) })
        return urlFilter.testURLAllowed(url) == URLFilterRuleActions(URLFilterActionAllow)
    }

    /// Raw filter action (URLFilterActionBlock = 0, Allow = 1, Unknown = 3) for a
    /// URL against the given simplified allow/block expressions. Block rules are
    /// evaluated before allow rules, mirroring -[SEBURLFilter testURLAllowed:].
    public static func filterAction(for url: URL, allowExpressions: [String], blockExpressions: [String]) throws -> Int {
        let urlFilter = SEBURLFilter()
        urlFilter.prohibitedList = NSMutableArray(array: try blockExpressions.flatMap { try expressions(for: $0, regex: false) })
        urlFilter.permittedList = NSMutableArray(array: try allowExpressions.flatMap { try expressions(for: $0, regex: false) })
        return Int(urlFilter.testURLAllowed(url))
    }

    /// Whether a URL gets ignored by the passed ignore list entries, which are
    /// sanitized exactly as in -[SEBURLFilter updateIgnoreRuleList].
    public static func isURLIgnored(_ url: URL, ignoreEntries: [Any]) throws -> Bool {
        let urlFilter = SEBURLFilter()
        urlFilter.ignoreList = NSMutableArray(array: try ignoreEntries.flatMap { try expressions(for: $0, regex: false) })
        return urlFilter.testURLIgnored(url)
    }

    /// Drives the production rule-processing loop (-[SEBURLFilter
    /// addFilterRuleExpressionsFromRules:]) with an arbitrary rule list and reports
    /// how many allow/block expressions were created and whether an error was
    /// returned. Each rule dict uses the settings keys "active"/"regex"/"action"/
    /// "expression"; the list may contain non-dictionary entries to test robustness.
    public static func processRules(_ rules: [Any]) -> (allowCount: Int, blockCount: Int, hadError: Bool) {
        let urlFilter = SEBURLFilter()
        urlFilter.permittedList = NSMutableArray()
        urlFilter.prohibitedList = NSMutableArray()
        let error = urlFilter.addFilterRuleExpressions(from: rules)
        return (urlFilter.permittedList.count, urlFilter.prohibitedList.count, error != nil)
    }
}
#endif
