//
//  SEBWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 19.03.21.
//

import Foundation

public class SEBiOSWKWebViewController: UIViewController, WKUIDelegate, SEBAbstractBrowserControllerDelegate {
    
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    public var sebWebView : WKWebView?

    public override func loadView() {
        let webFrame = UIScreen.main.bounds
        if sebWebView == nil {
            sebWebView = WKWebView.init(frame: webFrame)
        }
        let statusBarAppearance = navigationDelegate?.statusBarAppearance?() ?? 0
        sebWebView?.backgroundColor = (statusBarAppearance == mobileStatusBarAppearanceNone || statusBarAppearance == mobileStatusBarAppearanceLight ||
                                        statusBarAppearance == mobileStatusBarAppearanceExtendedNoneDark) ? UIColor.black : UIColor.white
        sebWebView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sebWebView?.scrollView.isScrollEnabled = true
        sebWebView?.translatesAutoresizingMaskIntoConstraints = true
        sebWebView?.uiDelegate = self
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
    
}
