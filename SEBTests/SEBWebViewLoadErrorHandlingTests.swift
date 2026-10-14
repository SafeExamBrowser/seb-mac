//
//  SEBWebViewLoadErrorHandlingTests.swift
//  SafeExamBrowserTests
//
//  Integration tests for the load error handling of the WKWebView based browser
//  (SEBAbstractModernWebView, SEBMAC-855): HTTP error responses which WebKit would
//  render as a blank page, dropped connections, page loads which never receive a
//  response ("page is still loading" watchdog) and the reload-loop guard for a
//  crashing web content process.
//
//  A real WKWebView loads pages from a local HTTP server on the loopback interface
//  (SEBTestHTTPServer below), which can misbehave on purpose: never answer a request,
//  answer late or drop the connection. The web view is driven through
//  SEBWebViewLoadingTestSupport (DEBUG only), which records what SEB reports to its
//  navigation delegate. The UI of the alerts (SEBBrowserWindow / iOS) isn't covered.
//
//  Uses XCTest to match the other unit tests in this target.
//

import XCTest
import Network
import Safe_Exam_Browser

// The test HTTP server uses Network.framework (macOS 10.14+), the deployment target is lower
@available(macOS 10.14, *)
final class SEBWebViewLoadErrorHandlingTests: XCTestCase {

    // Short watchdog timeouts, so the tests don't have to wait 30/60 s
    private let pendingNavigationTimeout: TimeInterval = 1.0
    private let pendingNavigationExtendedTimeout: TimeInterval = 1.5
    // Generous upper bound for anything which should happen "soon"
    private let eventTimeout: TimeInterval = 10

    private var server: SEBTestHTTPServer!
    private var webView: SEBWebViewLoadingTestSupport!

    override func setUpWithError() throws {
        try XCTSkipIf(SEBWebViewLoadingTestSupport.isContentFilterActive,
                      "SEB's URL content filter is active in the settings of the hosting app and could block the test server's pages")
        server = try SEBTestHTTPServer()
        webView = SEBWebViewLoadingTestSupport(pendingNavigationTimeout: pendingNavigationTimeout,
                                               pendingNavigationExtendedTimeout: pendingNavigationExtendedTimeout)
    }

    override func tearDownWithError() throws {
        webView?.close()
        webView = nil
        server?.stop()
        server = nil
    }

    // MARK: - HTTP responses

    func testSuccessfulPageLoad_finishesWithoutErrorOrPendingAlert() throws {
        server.setBehavior(.respond(status: 200, body: "<html><body>Exam</body></html>"), forPath: "/ok")
        webView.load(server.url("/ok"))

        XCTAssertTrue(waitForEvent("page finished loading") { $0 == .didFinishLoad })
        // Wait longer than the watchdog timeout: No alert must appear after the page loaded
        assertNoEvent(during: pendingNavigationTimeout + 1, "pending alert after successful load") { event in
            if case .loadIsPending = event { return true }
            return false
        }
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    func testServerErrorWithEmptyBody_isReportedAsLoadError() throws {
        server.setBehavior(.respond(status: 503, body: ""), forPath: "/unavailable")
        let url = server.url("/unavailable")
        webView.load(url)

        XCTAssertTrue(waitForEvent("load error 503") { $0.isLoadError(code: 503) })
        XCTAssertEqual(webView.displayedLoadErrors, [.didFailLoad(domain: "org.safeexambrowser.SEB", code: 503, failingURL: url.absoluteString)])
    }

    func testServerErrorWithContent_isReportedAsLoadError() throws {
        server.setBehavior(.respond(status: 500, body: "<html><body>Internal error</body></html>"), forPath: "/error")
        webView.load(server.url("/error"))

        XCTAssertTrue(waitForEvent("load error 500") { $0.isLoadError(code: 500) })
    }

    func testClientErrorWithEmptyBody_isReportedAsLoadError() throws {
        server.setBehavior(.respond(status: 404, body: ""), forPath: "/missing")
        webView.load(server.url("/missing"))

        XCTAssertTrue(waitForEvent("load error 404") { $0.isLoadError(code: 404) })
    }

    func testClientErrorWithContent_isDisplayedWithoutError() throws {
        // For example a custom "not found" or login page: It has content to display
        server.setBehavior(.respond(status: 404, body: "<html><body>Not found</body></html>"), forPath: "/custom-404")
        webView.load(server.url("/custom-404"))

        XCTAssertTrue(waitForEvent("page finished loading") { $0 == .didFinishLoad })
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    // MARK: - Network failures

    func testDroppedConnection_isReportedAsNetworkError() throws {
        server.setBehavior(.dropConnection, forPath: "/drop")
        webView.load(server.url("/drop"))

        XCTAssertTrue(waitForEvent("network load error") { event in
            if case .didFailLoad(let domain, let code, _) = event {
                return domain == NSURLErrorDomain && code != NSURLErrorCancelled
            }
            return false
        })
    }

    // MARK: - Page load which never receives a response

    func testUnansweredRequest_showsPendingAlert_withoutCancelingTheLoad() throws {
        server.setBehavior(.neverRespond, forPath: "/hang")
        let url = server.url("/hang")
        webView.load(url)

        XCTAssertTrue(waitForEvent("pending alert") { $0 == .loadIsPending(url: url) })
        // The load continues: No error, no completion, no new request
        assertNoEvent(during: 1, "load completed or failed while pending") { event in
            event == .didFinishLoad || event.isDisplayedLoadError
        }
        XCTAssertTrue(webView.isPendingAlertDisplayed)
        XCTAssertEqual(server.requestCount(forPath: "/hang"), 1)
    }

    func testPendingAlert_keepWaiting_alertsAgainLater() throws {
        server.setBehavior(.neverRespond, forPath: "/hang")
        let url = server.url("/hang")
        webView.load(url)
        XCTAssertTrue(waitForEvent("first pending alert") { $0 == .loadIsPending(url: url) })

        webView.answerPendingAlert(retry: false)

        XCTAssertTrue(waitForEvent("second pending alert after keep waiting", afterEventCount: webView.events.count) { $0 == .loadIsPending(url: url) })
        XCTAssertEqual(server.requestCount(forPath: "/hang"), 1, "Keep Waiting must not load the page again")
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    func testPendingAlert_retry_loadsPageAgain() throws {
        // The first request never receives a response, the retried one succeeds
        server.setBehaviors([.neverRespond, .respond(status: 200, body: "<html><body>Exam</body></html>")], forPath: "/flaky")
        let url = server.url("/flaky")
        webView.load(url)
        XCTAssertTrue(waitForEvent("pending alert") { $0 == .loadIsPending(url: url) })

        webView.answerPendingAlert(retry: true)

        XCTAssertTrue(waitForEvent("retried page finished loading") { $0 == .didFinishLoad })
        XCTAssertEqual(server.requestCount(forPath: "/flaky"), 2)
        // Canceling the hanging load when retrying must not be reported as error
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    func testResponseArrivingAfterPendingAlert_dismissesAlert_andLateAnswerIsIgnored() throws {
        // Slow server: Answers after the watchdog timeout
        server.setBehavior(.respondAfter(delay: pendingNavigationTimeout + 1, status: 200, body: "<html><body>Exam</body></html>"), forPath: "/slow")
        let url = server.url("/slow")
        webView.load(url)

        XCTAssertTrue(waitForEvent("pending alert") { $0 == .loadIsPending(url: url) })
        XCTAssertTrue(waitForEvent("alert dismissed when the response arrived") { $0 == .loadIsNoLongerPending })
        XCTAssertTrue(waitForEvent("page finished loading") { $0 == .didFinishLoad })
        XCTAssertFalse(webView.isPendingAlertDisplayed)

        // The user answers the meanwhile dismissed alert with Retry: This must be ignored
        webView.answerLastPendingAlertLate(retry: true)
        assertNoEvent(during: 1, "new load after late answer") { $0 == .didStartLoad }
        XCTAssertEqual(server.requestCount(forPath: "/slow"), 1)
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    // MARK: - Web content process termination

    func testRepeatedWebContentProcessTermination_isReportedAfterThreeReloads() throws {
        server.setBehavior(.respond(status: 200, body: "<html><body>Exam</body></html>"), forPath: "/ok")
        webView.load(server.url("/ok"))
        XCTAssertTrue(waitForEvent("page finished loading") { $0 == .didFinishLoad })

        // The first three terminations are handled by reloading the page
        for _ in 1...3 {
            webView.simulateWebContentProcessTermination()
        }
        XCTAssertEqual(webView.displayedLoadErrors, [])

        // The fourth one in a row (without a successful load in between) is reported
        webView.simulateWebContentProcessTermination()
        XCTAssertTrue(webView.displayedLoadErrors.contains { $0.isLoadError(code: NSURLErrorCannotDecodeContentData) })
    }

    func testWebContentProcessTerminationCounter_isResetBySuccessfulLoad() throws {
        server.setBehavior(.respond(status: 200, body: "<html><body>Exam</body></html>"), forPath: "/ok")
        webView.load(server.url("/ok"))
        XCTAssertTrue(waitForEvent("page finished loading") { $0 == .didFinishLoad })

        for _ in 1...3 {
            webView.simulateWebContentProcessTermination()
        }
        // A reload triggered by the terminations finishes successfully
        XCTAssertTrue(waitForEvent("reloaded page finished loading", afterEventCount: webView.events.count) { $0 == .didFinishLoad })

        // So the next termination is handled by reloading again, not reported
        webView.simulateWebContentProcessTermination()
        XCTAssertEqual(webView.displayedLoadErrors, [])
    }

    // MARK: - Helpers

    /// Waits until an event matching `predicate` was reported (at index >= `afterEventCount`)
    private func waitForEvent(_ description: String,
                              afterEventCount: Int = 0,
                              timeout: TimeInterval? = nil,
                              matching predicate: @escaping (SEBWebViewLoadingTestSupport.Event) -> Bool) -> Bool {
        if webView.events.dropFirst(afterEventCount).contains(where: predicate) {
            return true
        }
        let expectation = XCTestExpectation(description: description)
        expectation.assertForOverFulfill = false
        webView.onEvent = { event in
            if predicate(event) {
                expectation.fulfill()
            }
        }
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout ?? eventTimeout)
        webView.onEvent = nil
        if result != .completed {
            XCTFail("Timed out waiting for \(description). Events: \(webView.events)")
            return false
        }
        return true
    }

    /// Asserts that no event matching `predicate` is reported during `duration`
    private func assertNoEvent(during duration: TimeInterval,
                               _ description: String,
                               file: StaticString = #filePath,
                               line: UInt = #line,
                               matching predicate: @escaping (SEBWebViewLoadingTestSupport.Event) -> Bool) {
        let startCount = webView.events.count
        RunLoop.main.run(until: Date().addingTimeInterval(duration))
        let unexpected = webView.events.dropFirst(startCount).filter(predicate)
        XCTAssertTrue(unexpected.isEmpty, "Unexpected \(description): \(unexpected)", file: file, line: line)
    }
}


private extension SEBWebViewLoadingTestSupport.Event {

    func isLoadError(code expectedCode: Int) -> Bool {
        if case .didFailLoad(_, let code, _) = self {
            return code == expectedCode
        }
        return false
    }

    var isDisplayedLoadError: Bool {
        if case .didFailLoad(_, let code, _) = self {
            return code != NSURLErrorCancelled && code != 102 && code != 204
        }
        return false
    }
}


// MARK: - Test HTTP server

/// Minimal HTTP/1.1 server on the loopback interface, which answers requests by path
/// with scripted behaviors, including misbehaving ones.
@available(macOS 10.14, *)
final class SEBTestHTTPServer {

    enum Behavior {
        /// Answers immediately
        case respond(status: Int, body: String)
        /// Answers after a delay (slow server)
        case respondAfter(delay: TimeInterval, status: Int, body: String)
        /// Receives the request, but never answers and keeps the connection open
        case neverRespond
        /// Receives the request and closes the connection without answering
        case dropConnection
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "org.safeexambrowser.SEBTestHTTPServer")
    // Accessed on `queue` only
    private var behaviors: [String: [Behavior]] = [:]
    private var requestCounts: [String: Int] = [:]
    private var connections: [NWConnection] = []
    private(set) var port: UInt16 = 0

    init() throws {
        let parameters = NWParameters.tcp
        parameters.requiredInterfaceType = .loopback
        parameters.allowLocalEndpointReuse = true
        listener = try NWListener(using: parameters, on: .any)

        let ready = DispatchSemaphore(value: 0)
        var startError: Error?
        listener.stateUpdateHandler = { state in
            switch state {
            case .ready:
                ready.signal()
            case .failed(let error):
                startError = error
                ready.signal()
            default:
                break
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.handle(connection)
        }
        listener.start(queue: queue)
        if ready.wait(timeout: .now() + 5) == .timedOut {
            throw NSError(domain: "SEBTestHTTPServer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test HTTP server didn't start"])
        }
        if let startError = startError {
            throw startError
        }
        port = listener.port?.rawValue ?? 0
    }

    func url(_ path: String) -> URL {
        return URL(string: "http://127.0.0.1:\(port)\(path)")!
    }

    func setBehavior(_ behavior: Behavior, forPath path: String) {
        setBehaviors([behavior], forPath: path)
    }

    /// The n-th request for `path` gets the n-th behavior, the last one is repeated
    func setBehaviors(_ behaviors: [Behavior], forPath path: String) {
        queue.sync {
            self.behaviors[path] = behaviors
        }
    }

    func requestCount(forPath path: String) -> Int {
        return queue.sync { requestCounts[path] ?? 0 }
    }

    func stop() {
        queue.sync {
            connections.forEach { $0.cancel() }
            connections.removeAll()
        }
        listener.cancel()
    }

    // MARK: Connection handling (on `queue`)

    private func handle(_ connection: NWConnection) {
        connections.append(connection)
        connection.start(queue: queue)
        receiveRequest(on: connection, buffer: Data())
    }

    private func receiveRequest(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self else {
                return
            }
            var buffer = buffer
            if let data = data {
                buffer.append(data)
            }
            // Request headers are complete (request bodies aren't needed by the tests)
            if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)) {
                let header = String(decoding: buffer[..<headerEnd.lowerBound], as: UTF8.self)
                self.respond(to: header, on: connection)
            } else if error == nil && !isComplete {
                self.receiveRequest(on: connection, buffer: buffer)
            } else {
                self.close(connection)
            }
        }
    }

    private func respond(to requestHeader: String, on connection: NWConnection) {
        // Request line: "GET /path HTTP/1.1"
        let requestLine = requestHeader.components(separatedBy: "\r\n").first ?? ""
        let requestTarget = requestLine.components(separatedBy: " ").dropFirst().first ?? "/"
        let path = requestTarget.components(separatedBy: "?").first ?? requestTarget
        let count = (requestCounts[path] ?? 0) + 1
        requestCounts[path] = count

        guard let pathBehaviors = behaviors[path], !pathBehaviors.isEmpty else {
            send(status: 404, body: "Not found", on: connection)
            return
        }
        switch pathBehaviors[min(count, pathBehaviors.count) - 1] {
        case .respond(let status, let body):
            send(status: status, body: body, on: connection)
        case .respondAfter(let delay, let status, let body):
            queue.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.send(status: status, body: body, on: connection)
            }
        case .neverRespond:
            break
        case .dropConnection:
            close(connection)
        }
    }

    private func send(status: Int, body: String, on connection: NWConnection) {
        let bodyData = Data(body.utf8)
        // ASCII reason phrase (HTTPURLResponse.localizedString(forStatusCode:) is localized)
        let reasonPhrases = [200: "OK", 404: "Not Found", 500: "Internal Server Error", 503: "Service Unavailable"]
        let header = "HTTP/1.1 \(status) \(reasonPhrases[status] ?? "Status")\r\n" +
            "Content-Type: text/html; charset=utf-8\r\n" +
            "Content-Length: \(bodyData.count)\r\n" +
            "Connection: close\r\n\r\n"
        connection.send(content: Data(header.utf8) + bodyData, completion: .contentProcessed { [weak self] _ in
            self?.close(connection)
        })
    }

    private func close(_ connection: NWConnection) {
        connection.cancel()
        connections.removeAll { $0 === connection }
    }
}
