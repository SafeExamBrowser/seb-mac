//
//  SEBWebViewLoadingTestSupport.swift
//  SafeExamBrowser
//
//  Test-only harness which drives a real SEBAbstractModernWebView (the WKWebView
//  based browser, shared by macOS and iOS) with a mock navigation delegate. This
//  lets the integration tests load pages from a local test server and verify how
//  SEB reports load errors, HTTP error responses and page loads which never
//  receive a response (the "page is still loading" watchdog), without the UI of
//  the browser window. Compiled only in DEBUG builds — nothing ships in release.
//

#if DEBUG
import Foundation
import WebKit

public final class SEBWebViewLoadingTestSupport {

    public enum Event: Equatable, CustomStringConvertible {
        case didStartLoad
        case didFinishLoad
        case didFailLoad(domain: String, code: Int, failingURL: String?)
        case loadIsPending(url: URL?)
        case loadIsNoLongerPending

        public var description: String {
            switch self {
            case .didStartLoad:
                return "didStartLoad"
            case .didFinishLoad:
                return "didFinishLoad"
            case .didFailLoad(let domain, let code, let failingURL):
                return "didFailLoad(\(domain) \(code) \(failingURL ?? "<no URL>"))"
            case .loadIsPending(let url):
                return "loadIsPending(\(url?.absoluteString ?? "<no URL>"))"
            case .loadIsNoLongerPending:
                return "loadIsNoLongerPending"
            }
        }
    }

    /// All events reported by the web view, in order
    public private(set) var events: [Event] = []
    /// Called on the main thread for each reported event
    public var onEvent: ((Event) -> Void)?

    private let mockDelegate = MockNavigationDelegate()
    private var modernWebView: SEBAbstractModernWebView?

    /// Whether SEB's URL content filter is active in the settings of the hosting app.
    /// It might block the test server's pages, tests should be skipped then.
    public static var isContentFilterActive: Bool {
        let urlFilter = SEBURLFilter.shared()
        return urlFilter.enableURLFilter && urlFilter.enableContentFilter
    }

    public init(pendingNavigationTimeout: TimeInterval, pendingNavigationExtendedTimeout: TimeInterval) {
        mockDelegate.eventHandler = { [weak self] event in
            self?.events.append(event)
            self?.onEvent?(event)
        }
        let webView = SEBAbstractModernWebView(delegate: mockDelegate, configuration: nil)
        webView.pendingNavigationTimeout = pendingNavigationTimeout
        webView.pendingNavigationExtendedTimeout = pendingNavigationExtendedTimeout
        modernWebView = webView
    }

    public func load(_ url: URL) {
        modernWebView?.load(url)
    }

    /// Whether a "page is still loading" alert is currently displayed (waiting for an answer)
    public var isPendingAlertDisplayed: Bool {
        return mockDelegate.pendingAlertCompletionHandler != nil
    }

    /// Answers the displayed "page is still loading" alert like the user would
    public func answerPendingAlert(retry: Bool) {
        let completionHandler = mockDelegate.pendingAlertCompletionHandler
        mockDelegate.pendingAlertCompletionHandler = nil
        completionHandler?(retry)
    }

    /// Answers the most recent "page is still loading" alert even if SEB already
    /// dismissed it (simulates an answer arriving too late, which must be ignored)
    public func answerLastPendingAlertLate(retry: Bool) {
        mockDelegate.lastPendingAlertCompletionHandler?(retry)
    }

    /// Simulates WebKit reporting that the web content process terminated (crashed)
    public func simulateWebContentProcessTermination() {
        guard let modernWebView = modernWebView, let wkWebView = modernWebView.nativeWebView() as? WKWebView else {
            return
        }
        modernWebView.webViewWebContentProcessDidTerminate(wkWebView)
    }

    /// Load errors which SEB would display to the user, filtered the same way as
    /// SEBAbstractWebView does: Canceled loads (-999, e.g. replaced by a new load),
    /// "frame load interrupted" (102) and "plug-in handled load" (204) aren't displayed.
    public var displayedLoadErrors: [Event] {
        return events.filter { event in
            if case .didFailLoad(_, let code, _) = event {
                return code != NSURLErrorCancelled && code != 102 && code != 204
            }
            return false
        }
    }

    public func close() {
        mockDelegate.pendingAlertCompletionHandler = nil
        mockDelegate.lastPendingAlertCompletionHandler = nil
        modernWebView?.stopLoading()
        modernWebView?.closeWKWebView()
        modernWebView = nil
    }
}


/// Minimal navigation delegate, which allows all navigations and responses and
/// records the callbacks relevant for load error handling.
private final class MockNavigationDelegate: NSObject, SEBAbstractWebViewNavigationDelegate {

    var eventHandler: ((SEBWebViewLoadingTestSupport.Event) -> Void)?
    var pendingAlertCompletionHandler: ((Bool) -> Void)?
    var lastPendingAlertCompletionHandler: ((Bool) -> Void)?
    var currentURL: URL?

    private let configuration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        // Don't share cookies or caches with the hosting SEB app
        configuration.websiteDataStore = .nonPersistent()
        return configuration
    }()

    var wkWebViewConfiguration: WKWebViewConfiguration {
        return configuration
    }

    func decidePolicy(for navigationAction: WKNavigationAction, newTab: Bool, configuration: WKWebViewConfiguration?, downloadFilename: String?) -> SEBNavigationAction {
        let sebNavigationAction = SEBNavigationAction()
        sebNavigationAction.policy = SEBNavigationActionPolicy(SEBNavigationActionPolicyAllow)
        return sebNavigationAction
    }

    func decidePolicy(forMIMEType mimeType: String?, url: URL?, canShowMIMEType: Bool, isForMainFrame: Bool, suggestedFilename: String?, cookies: [HTTPCookie]?) -> SEBNavigationResponsePolicy {
        return SEBNavigationResponsePolicy(SEBNavigationResponsePolicyAllow)
    }

    func sebWebViewDidStartLoad() {
        eventHandler?(.didStartLoad)
    }

    func sebWebViewDidFinishLoad() {
        eventHandler?(.didFinishLoad)
    }

    func sebWebViewDidFailLoadWithError(_ error: Error) {
        let nsError = error as NSError
        let failingURL = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String
        eventHandler?(.didFailLoad(domain: nsError.domain, code: nsError.code, failingURL: failingURL))
    }

    func sebWebViewLoadIsPending(url: URL?, seconds: TimeInterval, completionHandler: @escaping (Bool) -> Void) {
        pendingAlertCompletionHandler = completionHandler
        lastPendingAlertCompletionHandler = completionHandler
        eventHandler?(.loadIsPending(url: url))
    }

    func sebWebViewLoadIsNoLongerPending() {
        pendingAlertCompletionHandler = nil
        eventHandler?(.loadIsNoLongerPending)
    }
}
#endif
