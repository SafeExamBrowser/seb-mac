//
//  SEBWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.21.
//  Copyright (c) 2010-2022 Daniel R. Schneider, ETH Zurich,
//  Educational Development and Technology (LET),
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 1.1 (the "License"); you may not use this file except in
//  compliance with the License. You may obtain a copy of the License at
//  http://www.mozilla.org/MPL/
//
//  Software distributed under the License is distributed on an "AS IS"
//  basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
//  License for the specific language governing rights and limitations
//  under the License.
//
//  The Original Code is Safe Exam Browser for Mac OS X.
//
//  The Initial Developer of the Original Code is Daniel R. Schneider.
//  Portions created by Daniel R. Schneider are Copyright
//  (c) 2010-2022 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation

public class SEBiOSWKWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SEBAbstractBrowserControllerDelegate {
    
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    public var scrollLockActive = false
    
    private var _sebWebView: WKWebView?
    private var webViewConfiguration: WKWebViewConfiguration?

    public var sebWebView: WKWebView? {
        if _sebWebView == nil {
            if webViewConfiguration == nil {
                webViewConfiguration = navigationDelegate?.wkWebViewConfiguration
            }
            DDLogDebug("WKWebViewConfiguration \(String(describing: webViewConfiguration))")
            let webFrame = UIScreen.main.bounds
            _sebWebView = WKWebView.init(frame: webFrame, configuration: webViewConfiguration!)
            let backgroundTintStyle = navigationDelegate?.backgroundTintStyle?() ?? SEBBackgroundTintStyleDark
            _sebWebView?.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? UIColor.black : UIColor.white
            _sebWebView?.scrollView.contentInsetAdjustmentBehavior = .always
            _sebWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            _sebWebView?.scrollView.isScrollEnabled = true
            _sebWebView?.translatesAutoresizingMaskIntoConstraints = true
            zoomScale = _sebWebView?.scrollView.zoomScale
            _sebWebView?.uiDelegate = self
            _sebWebView?.navigationDelegate = self
            _sebWebView?.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)            

            _sebWebView?.customUserAgent = navigationDelegate?.customSEBUserAgent
            urlFilter = SEBURLFilter.shared()
        }
        return _sebWebView
    }

    private var zoomScale: CGFloat?
    private var urlFilter: SEBURLFilter?

    public func updateZoomScale(_ contentZoomScale: Double) {
        zoomScale = sebWebView?.scrollView.zoomScale
        sebWebView?.scrollView.setZoomScale(zoomScale!, animated: true)
        if contentZoomScale != 1 {
            let js = "var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);"
            sebWebView?.evaluateJavaScript(js)
        }
    }
    
    convenience init(delegate: SEBAbstractWebViewNavigationDelegate, configuration: WKWebViewConfiguration?) {
        self.init()
        webViewConfiguration = configuration
        navigationDelegate = delegate
    }
    
    public func closeWKWebView() {
        _sebWebView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        _sebWebView?.removeFromSuperview()
        _sebWebView = nil
        self.removeFromParent()
    }
    
    public override func loadView() {
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            if let title = sebWebView?.title {
                self.navigationDelegate?.sebWebViewDidUpdateTitle?(title)
            }
        }
    }
    
    public func viewWillTransitionToSize() {
        zoomScale = sebWebView?.scrollView.zoomScale
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        sebWebView?.uiDelegate = self
        sebWebView?.scrollView.setZoomScale(zoomScale!, animated: animated)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        sebWebView?.uiDelegate = nil
    }
    
    public func nativeWebView() -> Any {
        return sebWebView as Any
    }
    
    public func url() -> URL? {
        return sebWebView?.url
    }
    
    public func pageTitle() -> String? {
        return sebWebView?.title
    }
    
    public func toggleScrollLock() {
        scrollLockActive = !scrollLockActive
        sebWebView?.scrollView.isScrollEnabled = !scrollLockActive
        sebWebView?.scrollView.bounces = !scrollLockActive
        if scrollLockActive {
            // Disable text/content selection
            sebWebView?.evaluateJavaScript("document.documentElement.style.webkitUserSelect='none';")
            // Disable selection context popup (copy/paste etc.)
            sebWebView?.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='none';")
            // Disable magnifier glass
                sebWebView?.evaluateJavaScript("document.body.style.webkitUserSelect='none';")
        } else {
            // Enable text/content selection
                sebWebView?.evaluateJavaScript("document.documentElement.style.webkitUserSelect='text';")
            // Enable selection context popup (copy/paste etc.)
                sebWebView?.evaluateJavaScript("document.documentElement.style.webkitTouchCallout='default';")
            // Enable magnifier glass
                sebWebView?.evaluateJavaScript("document.body.style.webkitUserSelect='default';")
        }
    }
    
    public func isScrollLockActive() -> Bool {
        return scrollLockActive
    }
    
    public func setAllowDictionaryLookup(_ allowDictionaryLookup: Bool) {
        _sebWebView?.allowsLinkPreview = allowDictionaryLookup
    }
    
    public func canGoBack() -> Bool {
        return sebWebView?.canGoBack ?? false
    }
    
    public func canGoForward() -> Bool {
        return sebWebView?.canGoForward ?? false
    }
    
    public func goBack() {
        sebWebView?.goBack()
    }
    
    public func goForward() {
        sebWebView?.goForward()
    }
    
    public func load(_ url: URL) {
        sebWebView?.load(URLRequest.init(url: url))
    }
    
    public func stopLoading() {
        sebWebView?.stopLoading()
    }
 
    
    public func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation) {
        navigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView,
                         didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation) {
        navigationDelegate?.webView?(webView, didReceiveServerRedirectForProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation, withError error: Error) {
        navigationDelegate?.webView?(webView, didFailProvisionalNavigation: navigation, withError: error)
    }
    
    public func webView(_ webView: WKWebView,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        navigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView,
                          didCommit navigation: WKNavigation) {
        navigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        navigationDelegate?.webView?(webView, didFinish: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation, withError error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DDLogError("[SEBiOSWKWebViewController webViewWebContentProcessDidTerminate:\(webView)]")
        navigationDelegate?.webViewWebContentProcessDidTerminate?(webView)
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        navigationDelegate?.webView?(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        navigationDelegate?.webView?(webView, decidePolicyFor: navigationResponse, decisionHandler: decisionHandler)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        return navigationDelegate?.webView?(webView, createWebViewWith: configuration, for: navigationAction, windowFeatures: windowFeatures)
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        self.navigationDelegate?.webViewDidClose?(webView)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    @available(iOS 15.0, *)
    public func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
        return (navigationDelegate?.permissionDecision?(for: type) ?? .deny)
    }
}

@available(macOS 11.3, iOS 14.5, *)
extension SEBiOSWKWebViewController {
    
    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        navigationDelegate?.webView?(webView, navigationAction: navigationAction, didBecome: download)
    }
}
