//
//  SEBAbstractModernWebView.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
//  Copyright (c) 2010-2021 Daniel R. Schneider, ETH Zurich,
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
//  (c) 2010-2021 Daniel R. Schneider, ETH Zurich, Educational Development
//  and Technology (LET), based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation

@objc public class SEBAbstractModernWebView: NSObject, SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate, WKScriptMessageHandler {
    
    public var wkWebViewConfiguration: WKWebViewConfiguration {
        let webViewConfiguration = navigationDelegate!.wkWebViewConfiguration
        let userContentController = WKUserContentController()
        let appVersion = navigationDelegate?.appVersion?()
        let jsApiCode = """
        window.SafeExamBrowser = { \
          version: '\(appVersion ?? "")', \
          security: { \
            browserExamKey: '', \
            configKey: '', \
            appVersion: '\(appVersion ?? "")', \
            updateKeys: function (callback) { \
              window.webkit.messageHandlers.updateKeys.postMessage(callback.name); \
            } \
          } \
        }
"""
        let jsApiUserScript = WKUserScript(source: jsApiCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(jsApiUserScript)
        if let pageJavaScriptCode = navigationDelegate?.pageJavaScript {
            let pageModifyUserScript = WKUserScript(source: pageJavaScriptCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(pageModifyUserScript)
            let preferences = UserDefaults.standard
            let allowSpellCheck = !(navigationDelegate?.overrideAllowSpellCheck ?? false) && preferences.secureBool(forKey: "org_safeexambrowser_SEB_allowSpellCheck")
            let controlSpellCheckCode = "SEB_AllowSpellCheck(\(allowSpellCheck ? "true" : "false"))"
            let controlSpellCheckUserScript = WKUserScript(source: controlSpellCheckCode, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
            userContentController.addUserScript(controlSpellCheckUserScript)
        }
        userContentController.add(self, name: "updateKeys")
        webViewConfiguration.userContentController = userContentController
        return webViewConfiguration
    }
    
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        if message.name == "updateKeys" {
            guard let webView = (browserControllerDelegate?.nativeWebView()) as? WKWebView else {
                return
            }
            print(message.body as Any)
            let parameter = message.body as? String
            let browserExamKey = navigationDelegate?.browserExamKey?(for: webView.url!)
            let configKey = navigationDelegate?.configKey?(for: webView.url!)
            webView.evaluateJavaScript("SafeExamBrowser.security.browserExamKey = '\(browserExamKey ?? "")';SafeExamBrowser.security.configKey = '\(configKey ?? "")';") { (response, error) in
                if let _ = error {
                    print(error as Any)
                } else {
                    guard let callback = parameter else {
                        return
                    }
                    webView.evaluateJavaScript(callback + "();") { (response, error) in
                        if let _ = error {
                            print(error as Any)
                        }
                    }
                }
            }
        }
    }
    
    public var customSEBUserAgent: String {
        return navigationDelegate!.customSEBUserAgent!
    }
    
    @objc public var browserControllerDelegate: SEBAbstractBrowserControllerDelegate?
    @objc weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?

    private var firstLoad = true
    private var allowSpellCheck : Bool?

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
    
    public  func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        browserControllerDelegate?.viewWillTransitionToSize?()
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
    
    public func shouldStartLoadFormSubmittedURL(_ url: URL) {
        browserControllerDelegate?.shouldStartLoadFormSubmittedURL?(url)
    }
    
    public func sessionTaskDidCompleteSuccessfully(_ task: URLSessionTask) {
        browserControllerDelegate?.sessionTaskDidCompleteSuccessfully?(task)
    }
    
    /// SEBAbstractWebViewNavigationDelegate Methods

    public func setLoading(_ loading: Bool) {
        navigationDelegate?.setLoading(loading)
    }
    
    public func setCanGoBack(_ canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.setCanGoBack(canGoBack, canGoForward: canGoForward)
    }
    
    public func openNewTab(with url: URL) -> SEBAbstractWebView? {
        return navigationDelegate?.openNewTab(with: url) ?? nil
    }

    public func examine(_ cookies: [HTTPCookie]) {
        navigationDelegate?.examine(cookies)
    }
    
    public func sebWebViewDidStartLoad() {
        navigationDelegate?.sebWebViewDidStartLoad?()
    }
    
    public func sebWebViewDidFinishLoad() {
        navigationDelegate?.sebWebViewDidFinishLoad?()
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidStartLoad?()
    }
    
    public func webView(_ webView: WKWebView,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        navigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView,
                        didCommit navigation: WKNavigation) {
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        navigationDelegate?.sebWebViewDidFinishLoad?()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var newTab = false
        if navigationAction.targetFrame == nil {
            newTab = true;
        }
        let shouldStartLoad = (navigationDelegate?.sebWebViewShouldStartLoad!(with: navigationAction.request, navigationAction: navigationAction, newTab: newTab))!
        if shouldStartLoad {
            decisionHandler(.allow)
        } else {
            decisionHandler(.cancel)
        }
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
        httpCookieStore.getAllCookies{ cookies in
            let canShowMIMEType = navigationResponse.canShowMIMEType
            let isForMainFrame = navigationResponse.isForMainFrame
            let mimeType = navigationResponse.response.mimeType
            let url = navigationResponse.response.url
            let suggestedFilename = navigationResponse.response.suggestedFilename
            let policy = self.navigationDelegate?.sebWebViewDecidePolicy?(forMIMEType: mimeType, url: url, canShowMIMEType: canShowMIMEType, isForMainFrame: isForMainFrame, suggestedFilename: suggestedFilename, cookies: cookies) ?? true
            if policy {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
    
    public func sebWebViewDidFailLoadWithError(_ error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
    }
    
    public func sebWebViewShouldStartLoad(with request: URLRequest, navigationAction: WKNavigationAction, newTab: Bool) -> Bool {
        return (navigationDelegate?.sebWebViewShouldStartLoad?(with: request, navigationAction: navigationAction, newTab: newTab) ?? false)
    }
    
    public func sebWebViewDidUpdateTitle(_ title: String?) {
        navigationDelegate?.sebWebViewDidUpdateTitle?(title)
    }
    
    public func sebWebViewDidUpdateProgress(_ progress: Double) {
        navigationDelegate?.sebWebViewDidUpdateProgress?(progress)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    private func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
    }

    public func modifyRequest(_ request: URLRequest) -> URLRequest {
        return (navigationDelegate?.modifyRequest?(request)) ?? request
    }
    
    public func browserExamKey(for url: URL) -> String {
        return (navigationDelegate?.browserExamKey?(for: url) ?? "")
    }
    
    public func configKey(for url: URL) -> String {
        return (navigationDelegate?.configKey?(for: url) ?? "")
    }
    
    public func appVersion() -> String {
        return (navigationDelegate?.appVersion?() ?? "")
    }
    
    public func setTitle(_ title: String) {
        navigationDelegate?.setTitle(title)
    }
    
    public func backgroundTintStyle () -> SEBBackgroundTintStyle {
        return navigationDelegate?.backgroundTintStyle?() ?? SEBBackgroundTintStyleDark
    }
    
    public var uiAlertController: Any?
    
    public func loadWebPageOrSearchResult(with webSearchString: String) {
        navigationDelegate?.loadWebPageOrSearchResult?(with: webSearchString)
    }
    
    public func openCloseSliderForNewTab() {
        navigationDelegate?.openCloseSliderForNewTab?()
    }
    
    public func switchToTab(_ sender: Any?) {
        navigationDelegate?.switchToTab?(sender)
    }
    
    public func switchToNextTab() {
        navigationDelegate?.switchToNextTab?()
    }
    
    public func switchToPreviousTab() {
        navigationDelegate?.switchToPreviousTab?()
    }
    
    public func closeTab() {
        navigationDelegate?.closeTab?()
    }
    
    public func conditionallyDownloadAndOpenSEBConfig(from url: URL) {
        navigationDelegate?.conditionallyDownloadAndOpenSEBConfig?(from: url)
    }
    
    public func conditionallyOpenSEBConfig(from sebConfigData: Data) {
        navigationDelegate?.conditionallyOpenSEBConfig?(from: sebConfigData)
    }
    

}
