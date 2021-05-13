//
//  SEBWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.21.
//

import Foundation

public class SEBiOSWKWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SEBAbstractBrowserControllerDelegate {
    
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    public var scrollLockActive = false
    
    public var sebWebView : WKWebView?
    
    private var zoomScale : CGFloat?

    private var quitURLTrimmed : String?
    private var urlFilter : SEBURLFilter?
    
    public override func loadView() {
        let webFrame = UIScreen.main.bounds
        if sebWebView == nil {
            let webViewConfiguration = navigationDelegate?.wkWebViewConfiguration
            sebWebView = WKWebView.init(frame: webFrame, configuration: webViewConfiguration!)
        }
        let backgroundTintStyle = navigationDelegate?.backgroundTintStyle?() ?? SEBBackgroundTintStyleDark
        sebWebView?.backgroundColor = backgroundTintStyle == SEBBackgroundTintStyleDark ? UIColor.black : UIColor.white
        sebWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sebWebView?.scrollView.isScrollEnabled = true
        sebWebView?.translatesAutoresizingMaskIntoConstraints = true
        zoomScale = sebWebView?.scrollView.zoomScale
        sebWebView?.uiDelegate = self
        sebWebView?.navigationDelegate = self
        
        let preferences = UserDefaults.standard
        sebWebView?.customUserAgent = navigationDelegate?.customSEBUserAgent
        quitURLTrimmed = preferences.secureString(forKey: "org_safeexambrowser_SEB_quitURL")?.trimmingCharacters(in: CharacterSet.init(charactersIn: "/"))
        urlFilter = SEBURLFilter.shared()
    }
    
    public func viewWillTransitionToSize() {
        zoomScale = sebWebView?.scrollView.zoomScale
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        sebWebView?.uiDelegate = self
        sebWebView?.scrollView.setZoomScale(zoomScale!, animated: true)
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
    
    public func reload() {
        sebWebView?.reload()
    }
    
    public func load(_ url: URL) {
        sebWebView?.load(URLRequest.init(url: url))
    }
    
    public func stopLoading() {
        sebWebView?.stopLoading()
    }
 
    
    public func webView(_ webView: WKWebView,  shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return false
    }

    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.webView?(webView, didStartProvisionalNavigation: navigation)
    }
    
    public func webView(_ webView: WKWebView,
                         didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    public func webView(_ webView: WKWebView,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        navigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView,
                          didCommit navigation: WKNavigation!) {
        navigationDelegate?.webView?(webView, didCommit: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationDelegate?.webView?(webView, didFinish: navigation)
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
        
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
        if navigationAction.targetFrame == nil {
            _ = navigationDelegate?.sebWebViewShouldStartLoad!(with: navigationAction.request, navigationAction: navigationAction, newTab:true)
        }
        return nil
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
}
