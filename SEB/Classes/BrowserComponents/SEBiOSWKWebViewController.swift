//
//  SEBWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.21.
//

import Foundation

public class SEBiOSWKWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, SEBAbstractBrowserControllerDelegate {
    
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    public var sebWebView : WKWebView?

    private var quitURLTrimmed : String?
    private var allowSpellCheck : Bool?
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
        sebWebView?.uiDelegate = self
        
        let preferences = UserDefaults.standard
        
        allowSpellCheck = preferences.secureBool(forKey: "org_safeexambrowser_SEB_allowSpellCheck")
        quitURLTrimmed = preferences.secureString(forKey: "org_safeexambrowser_SEB_quitURL")?.trimmingCharacters(in: CharacterSet.init(charactersIn: "/"))
        urlFilter = SEBURLFilter.shared()
    }
    
    public override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        sebWebView?.scrollView .setZoomScale(0, animated: true)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        sebWebView?.uiDelegate = self
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
 
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidStartLoad?(nil)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidFinishLoad?(nil)
        
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationDelegate?.sebWebView?(nil, didFailLoadWithError: error)
        
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let shouldStartLoad = (navigationDelegate?.sebWebView?(nil, shouldStartLoadWith: navigationAction.request, navigationAction: navigationAction))!
        if shouldStartLoad {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
//            navigationDelegate?.sebWebView?(nil, shouldStartLoadWith: navigationAction.request, navigationAction: navigationAction)
        }
        return nil
    }
}
