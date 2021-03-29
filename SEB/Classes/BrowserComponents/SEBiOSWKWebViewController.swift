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
    private var allowSpellCheck : Bool?
    private var sendBrowserExamKey : Bool?
    private var urlFilter : SEBURLFilter?
    
    public override func loadView() {
        let webFrame = UIScreen.main.bounds
        if sebWebView == nil {
            let webConfiguration = WKWebViewConfiguration()
            webConfiguration.dataDetectorTypes = []
            sebWebView = WKWebView.init(frame: webFrame, configuration: webConfiguration)
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
        
        allowSpellCheck = preferences.secureBool(forKey: "org_safeexambrowser_SEB_allowSpellCheck")
        sendBrowserExamKey = preferences.secureBool(forKey: "org_safeexambrowser_SEB_sendBrowserExamKey")
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
        if sendBrowserExamKey! {
            guard let customRequest = navigationDelegate?.modifyRequest?(URLRequest(url: url)) else {
                return
            }
            sebWebView?.load(customRequest)

        } else {
            sebWebView?.load(URLRequest.init(url: url))
        }
    }
    
    public func stopLoading() {
        sebWebView?.stopLoading()
    }
 
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidStartLoad?()
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidFinishLoad?()
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
        
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var newTab = false
        if navigationAction.targetFrame == nil {
            newTab = true;
        }
        let shouldStartLoad = (navigationDelegate?.sebWebViewShouldStartLoad!(with: navigationAction.request, navigationAction: navigationAction, newTab: newTab))!
        if shouldStartLoad {
            if sendBrowserExamKey! {
                if navigationAction.request.httpMethod != "GET" || navigationAction.request.value(forHTTPHeaderField: SEBConfigKeyHeaderKey) != nil {
                    // not a GET or already a custom request - continue
                    decisionHandler(.allow)
                    return
                }
                decisionHandler(.cancel)
                load(navigationAction.request.url!)
            } else {
                decisionHandler(.allow)
            }
        } else {
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            _ = navigationDelegate?.sebWebViewShouldStartLoad!(with: navigationAction.request, navigationAction: navigationAction, newTab:true)
        }
        return nil
    }
}
