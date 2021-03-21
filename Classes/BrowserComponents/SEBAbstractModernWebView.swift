//
//  SEBAbstractModernWebView.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
//

import Foundation

@objc public class SEBAbstractModernWebView: NSObject, SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate {
    
    @objc public var browserControllerDelegate: SEBAbstractBrowserControllerDelegate?
    @objc weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?


    @objc public override init() {
        super.init()
        let sebWKWebViewController = SEBiOSWKWebViewController()
        sebWKWebViewController.navigationDelegate = self
        self.browserControllerDelegate = sebWKWebViewController
    }
    
    public func loadView() {
        browserControllerDelegate?.loadView?()
    }
    
    public func didMoveToParentViewController() {
        browserControllerDelegate?.didMoveToParentViewController?()
    }
    
    public func viewDidLayoutSubviews() {
        browserControllerDelegate?.viewDidLayoutSubviews?()
    }
    
    public func viewWillTransitionToSize() {
        browserControllerDelegate?.viewWillTransitionToSize?()
    }
    
    public func viewWillAppear(_ animated: Bool) {
        browserControllerDelegate?.viewWillAppear?(animated)
    }
    
    public func viewDidAppear(_ animated: Bool) {
        browserControllerDelegate?.viewDidAppear?(animated)
    }
    
    public func viewWillDisappear(_ animated: Bool) {
        browserControllerDelegate?.viewWillDisappear?(animated)
    }
    
    public func nativeWebView() -> Any {
        return browserControllerDelegate?.nativeWebView() as Any
    }
    
    public func url() -> URL? {
        return browserControllerDelegate?.url()
    }
    
    public func pageTitle() -> String? {
        return browserControllerDelegate?.pageTitle()
    }
    
    public func canGoBack() -> Bool {
        return browserControllerDelegate?.canGoBack() ?? false
    }
    
    public func canGoForward() -> Bool {
        return browserControllerDelegate?.canGoForward() ?? false
    }
    
    public func goBack() {
        browserControllerDelegate?.goBack()
    }
    
    public func goForward() {
        browserControllerDelegate?.goForward()
    }
    
    public func reload() {
        browserControllerDelegate?.reload()
    }
    
    public func load(_ url: URL) {
        browserControllerDelegate?.load(url)
    }
    
    public func stopLoading() {
        browserControllerDelegate?.stopLoading()
    }

    public func toggleScrollLock() {
        browserControllerDelegate?.toggleScrollLock?()
    }
    
    public func isScrollLockActive() -> Bool {
        return browserControllerDelegate?.isScrollLockActive?() ?? false
    }
    
    public func loadWebPageOrSearchResult(with webSearchString: String) {
        browserControllerDelegate?.loadWebPageOrSearchResult?(with: webSearchString)
    }
    
    public func openCloseSliderForNewTab() {
        browserControllerDelegate?.openCloseSliderForNewTab?()
    }
    
    public func switchToTab(_ sender: Any?) {
        browserControllerDelegate?.switchToTab?(sender)
    }
    
    public func switchToNextTab() {
        browserControllerDelegate?.switchToNextTab?()
    }
    
    public func switchToPreviousTab() {
        browserControllerDelegate?.switchToPreviousTab?()
    }
    
    public func closeTab() {
        browserControllerDelegate?.closeTab?()
    }
    
    public func conditionallyDownloadAndOpenSEBConfig(from url: URL) {
        browserControllerDelegate?.conditionallyDownloadAndOpenSEBConfig?(from: url)
    }
    
    public func conditionallyOpenSEBConfig(from sebConfigData: Data) {
        browserControllerDelegate?.conditionallyOpenSEBConfig?(from: sebConfigData)
    }
    
    public func shouldStartLoadFormSubmittedURL(_ url: URL) {
        browserControllerDelegate?.shouldStartLoadFormSubmittedURL?(url)
    }
    
    public func sessionTaskDidCompleteSuccessfully(_ task: URLSessionTask) {
        browserControllerDelegate?.sessionTaskDidCompleteSuccessfully?(task)
    }
    
    public func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        browserControllerDelegate?.present?(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    /// SEBAbstractWebViewNavigationDelegate Methods

    public func setLoading(_ loading: Bool) {
        navigationDelegate?.setLoading(loading)
    }
    
    public func setCanGoBack(_ canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.setCanGoBack(canGoBack, canGoForward: canGoForward)
    }
    
    public func examine(_ cookies: [HTTPCookie]) {
        navigationDelegate?.examine(cookies)
    }
    
    public func sebWebViewDidStartLoad(_ sebWebView: SEBAbstractWebView?) {
        navigationDelegate?.sebWebViewDidStartLoad?(sebWebView)
    }
    
    public func sebWebViewDidFinishLoad(_ sebWebView: SEBAbstractWebView?) {
        navigationDelegate?.sebWebViewDidFinishLoad?(sebWebView)
    }
    
    public func sebWebView(_ sebWebView: SEBAbstractWebView?, didFailLoadWithError error: Error) {
        navigationDelegate?.sebWebView?(sebWebView, didFailLoadWithError: error)
    }
    
    public func sebWebView(_ sebWebView: SEBAbstractWebView?, shouldStartLoadWith request: URLRequest, navigationAction: WKNavigationAction) -> Bool {
        return navigationDelegate?.sebWebView?(sebWebView, shouldStartLoadWith: request, navigationAction: navigationAction) ?? false
    }
    
    public func sebWebView(_ sebWebView: SEBAbstractWebView?, didUpdateTitle title: String?) {
        navigationDelegate?.sebWebView?(sebWebView, didUpdateTitle: title)
    }
    
    public func sebWebView(_ sebWebView: SEBAbstractWebView?, didUpdateProgress progress: Double) {
        navigationDelegate?.sebWebView?(sebWebView, didUpdateProgress: progress)
    }
    
    public func setTitle(_ title: String) {
        navigationDelegate?.setTitle?(title)
    }
    
    public func statusBarAppearance() -> UInt {
        return navigationDelegate?.statusBarAppearance?() ?? 0
    }
    
    public var uiAlertController: Any?
    
    
}
