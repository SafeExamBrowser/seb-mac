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
    
    private var sebWebView: WKWebView {
        let webView = nativeWebView() as! WKWebView
        return webView
    }
    
    private let defaultPageZoom = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableZoomPage") ? UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_defaultPageZoomLevel") : WebViewDefaultPageZoom
    private let defaultTextZoom = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableZoomText") ? UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_defaultTextZoomLevel") : WebViewDefaultTextZoom
    public var pageZoom = WebViewDefaultPageZoom
    private var textZoom = WebViewDefaultTextZoom

    private var downloadFilename: String?

    public var downloadingSEBConfig = false
    
    public var wkWebViewConfiguration: WKWebViewConfiguration {
        let webViewConfiguration = navigationDelegate!.wkWebViewConfiguration
        let userContentController = WKUserContentController()
        let appVersion = navigationDelegate?.appVersion?()
        let jsApiCode = """
        window.SafeExamBrowser = {
          version: '\(appVersion ?? "")',
          security: {
            browserExamKey: '',
            configKey: '',
            appVersion: '\(appVersion ?? "")',
            updateKeys: function (callback) {
              if (callback) {
                window.webkit.messageHandlers.updateKeys.postMessage(callback.name);
              } else {
                window.webkit.messageHandlers.updateKeys.postMessage();
              }
            }
          }
        }
"""
        let jsApiUserScript = WKUserScript(source: jsApiCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
        userContentController.addUserScript(jsApiUserScript)
        if let pageJavaScriptCode = navigationDelegate?.pageJavaScript {
            let pageModifyUserScript = WKUserScript(source: pageJavaScriptCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(pageModifyUserScript)
            let allowSpellCheck = navigationDelegate?.allowSpellCheck ?? false
            let controlSpellCheckCode = "SEB_AllowSpellCheck(\(allowSpellCheck ? "true" : "false"))"
            let controlSpellCheckUserScript = WKUserScript(source: controlSpellCheckCode, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
            userContentController.addUserScript(controlSpellCheckUserScript)
        }
        userContentController.add(self, name: "updateKeys")
        webViewConfiguration!.userContentController = userContentController
#if os(macOS)
        if #available(macOS 10.12.3, *) {
            webViewConfiguration!.preferences.tabFocusesLinks = true
        }
#endif
        return webViewConfiguration!
    }
    
    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        if message.name == "updateKeys" {
            print(message.body as Any)
            let parameter = message.body as? String
            updateKeyJSVariables(sebWebView) { response, error in
                if let _ = error {
                    print(error as Any)
                } else {
                    guard let callback = parameter else {
                        return
                    }
                    self.sebWebView.evaluateJavaScript(callback + "();") { (response, error) in
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

    @objc public init(delegate: SEBAbstractWebViewNavigationDelegate) {
        super.init()
        navigationDelegate = delegate
        #if os(iOS)
        let sebWKWebViewController = SEBiOSWKWebViewController(delegate: self)
        self.browserControllerDelegate = sebWKWebViewController
        #elseif os(macOS)
        let sebWKWebViewController = SEBOSXWKWebViewController(delegate: self)
        self.browserControllerDelegate = sebWKWebViewController
        #endif
        
        let developerExtrasEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_allowDeveloperConsole")
        sebWebView.setValue(developerExtrasEnabled, forKey: "allowsRemoteInspection")
        
        pageZoom = defaultPageZoom
        textZoom = defaultTextZoom
    }
    
    public func loadView() {
        browserControllerDelegate!.loadView?()
    }
    
    public func didMoveToParentViewController() {
        browserControllerDelegate!.didMoveToParentViewController?()
    }
    
    public func viewDidLayout() {
        browserControllerDelegate!.viewDidLayout?()
    }
    
    public func viewDidLayoutSubviews() {
        browserControllerDelegate!.viewDidLayoutSubviews?()
    }
    
    public func viewWillTransitionToSize() {
        browserControllerDelegate!.viewWillTransitionToSize?()
    }
    
    public func viewDidLoad() {
        browserControllerDelegate!.viewDidLoad?()
    }
    
    public func viewWillAppear() {
        browserControllerDelegate!.viewWillAppear?()
    }
    
    public func viewWillAppear(_ animated: Bool) {
        browserControllerDelegate!.viewWillAppear?(animated)
    }
    
    public func viewDidAppear() {
        browserControllerDelegate!.viewDidAppear?()
    }

    public func viewDidAppear(_ animated: Bool) {
        browserControllerDelegate!.viewDidAppear?(animated)
    }
    
    public func viewWillDisappear() {
        browserControllerDelegate!.viewWillDisappear?()
    }
    
    public func viewWillDisappear(_ animated: Bool) {
        browserControllerDelegate!.viewWillDisappear?(animated)
    }
    
    public func viewDidDisappear() {
        browserControllerDelegate!.viewDidDisappear?()
    }
    
    public func viewDidDisappear(_ animated: Bool) {
        browserControllerDelegate!.viewDidDisappear?(animated)
    }
    
    public func nativeWebView() -> Any {
        return browserControllerDelegate!.nativeWebView!() as Any
    }
    
    public func url() -> URL? {
        return browserControllerDelegate!.url?()
    }
    
    public func pageTitle() -> String? {
        return browserControllerDelegate!.pageTitle?()
    }
    
    public func canGoBack() -> Bool {
        return browserControllerDelegate!.canGoBack?() ?? false
    }
    
    public func canGoForward() -> Bool {
        return browserControllerDelegate!.canGoForward?() ?? false
    }
    
    public func goBack() {
        browserControllerDelegate!.goBack!()
    }
    
    public func goForward() {
        browserControllerDelegate!.goForward!()
    }
    
    public func clearBackForwardList() {
        browserControllerDelegate!.clearBackForwardList?()
    }
    
    public func reload() {
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince:NSDate.distantPast, completionHandler:{
            if let url = self.sebWebView.url {
                self.load(url)
            } else {
                if let currentURL = self.navigationDelegate?.currentURL! {
                    self.load(currentURL)
                }
            }
        })
        pageZoom = defaultPageZoom
        textZoom = defaultTextZoom
    }
    
    public func load(_ url: URL) {
        browserControllerDelegate!.load!(url)
    }
    
    public func stopLoading() {
        browserControllerDelegate!.stopLoading!()
    }

    fileprivate func setPageZoom() {
        if (pageZoom <= WebViewMaxPageZoom && pageZoom >= WebViewMinPageZoom) {
            if #available(macOS 11.0, iOS 14.0, *) {
#if os(iOS)
                if pageZoom >= 1 {
                    let iOSPageZoom = (abs((pageZoom - 1) / (WebViewMaxPageZoom - 1) - 1) * (1 - WebViewMinPageZoom)) + WebViewMinPageZoom
                    sebWebView.pageZoom = iOSPageZoom
                    if pageZoom != 1 {
                        let js = """
                                var images = document.images;
                                for (var i = 0, max = images.length; i < max; i++)
                                {
                                    var width = images[i].width;
                                    var height = images[i].height;
                                    images[i].width = width * \(pageZoom);
                                    images[i].height = height * \(pageZoom);
                                }
    """
                        sebWebView.evaluateJavaScript(js) { (response, error) in
                            if let _ = error {
                                    print(error as Any)
                            }
                        }
                    }
                } else {
                    let js = "document.documentElement.style.zoom = '\(pageZoom)'; \(textZoomJS(zoomLevel: pageZoom))"
                    sebWebView.evaluateJavaScript(js) { (response, error) in
                        if let _ = error {
                                print(error as Any)
                        }
                    }
                }
#else
                sebWebView.pageZoom = pageZoom
#endif
            } else {
                let js = "document.documentElement.style.zoom = '\(pageZoom)'"
                sebWebView.evaluateJavaScript(js) { (response, error) in
                    if let _ = error {
                        print(error as Any)
                    }
                    self.browserControllerDelegate?.updateZoomScale?()
                }
            }
        }
    }
    
    public func zoomPageIn() {
        if pageZoom < WebViewMaxPageZoom {
            pageZoom += 0.1
            setPageZoom()
        }
    }
    
    public func zoomPageOut() {
        if pageZoom > WebViewMinPageZoom {
            pageZoom -= 0.1
            setPageZoom()
        }
    }
    
    public func zoomPageReset() {
        pageZoom = defaultPageZoom
        setPageZoom()
    }
    
    private func textZoomJS(zoomLevel: Double) -> String {
        let fontSize = Int(WebViewDefaultTextSize * zoomLevel)
        return """
                function zoomTextForTagName(tag) {
                    var elements = document.getElementsByTagName(tag);
                    for (var i = 0, max = elements.length; i < max; i++)
                    {
                        var computedFontSize = parseInt(window.getComputedStyle(elements[i]).fontSize, 10);
                        computedFontSize *= \(zoomLevel);
                        elements[i].style.fontSize = computedFontSize + 'px';
                    }
                }
                document.getElementsByTagName('body')[0].style.fontSize = '\(fontSize)%';
                zoomTextForTagName('p');
                zoomTextForTagName('span');
                zoomTextForTagName('em');
                zoomTextForTagName('a');
                zoomTextForTagName('ul');
                zoomTextForTagName('li');
                zoomTextForTagName('h1');
                zoomTextForTagName('h2');
                zoomTextForTagName('h3');
                zoomTextForTagName('h4');
                zoomTextForTagName('h5');
                zoomTextForTagName('h6');
"""
    }
    

    fileprivate func setTextSize() {
        if (pageZoom == 1 && textZoom != 1 && textZoom <= WebViewMaxTextZoom && textZoom >= WebViewMinTextZoom) {
            let js = textZoomJS(zoomLevel: textZoom)
            sebWebView.evaluateJavaScript(js) { (response, error) in
                if let _ = error {
                    print(error as Any)
                }
            }
        }
    }
    
    public func textSizeIncrease() {
        if textZoom < WebViewMaxTextZoom {
            textZoom += 0.1
            setTextSize()
        }
    }
    
    public func textSizeDecrease() {
        if textZoom > WebViewMinTextZoom {
            textZoom -= 0.1
            setTextSize()
        }
    }
    
    public func textSizeReset() {
        textZoom = defaultTextZoom
        setTextSize()
    }
    
    public func privateCopy(_ sender: Any) {
        browserControllerDelegate?.privateCopy?(sender)
    }
    
    public func privateCut(_ sender: Any) {
        browserControllerDelegate?.privateCut?(sender)
    }
    
    public func privatePaste(_ sender: Any) {
        browserControllerDelegate?.privatePaste?(sender)
    }
    
    public func toggleScrollLock() {
        browserControllerDelegate!.toggleScrollLock?()
    }
    
    public func isScrollLockActive() -> Bool {
        return browserControllerDelegate!.isScrollLockActive?() ?? false
    }
    
    public func setPrivateClipboardEnabled(_ privateClipboardEnabled: Bool) {
        browserControllerDelegate!.setPrivateClipboardEnabled?(privateClipboardEnabled)
    }
    
    public func setAllowDictionaryLookup(_ allowDictionaryLookup: Bool) {
        browserControllerDelegate!.setAllowDictionaryLookup?(allowDictionaryLookup)
    }
    
    public func setAllowPDFPlugIn(_ allowPDFPlugIn: Bool) {
        browserControllerDelegate!.setAllowPDFPlugIn?(allowPDFPlugIn)
    }
    
    public func sessionTaskDidCompleteSuccessfully(_ task: URLSessionTask) {
        browserControllerDelegate!.sessionTaskDidCompleteSuccessfully?(task)
    }
    
    /// SEBAbstractWebViewNavigationDelegate Methods

    public func setLoading(_ loading: Bool) {
        navigationDelegate?.setLoading!(loading)
    }
    
    public func setCanGoBack(_ canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.setCanGoBack!(canGoBack, canGoForward: canGoForward)
    }
    
    public func openNewTab(with url: URL) -> SEBAbstractWebView {
        return (navigationDelegate?.openNewTab!(with: url))!
    }

    public func examine(_ cookies: [HTTPCookie], url: URL) {
        navigationDelegate?.examine?(cookies, for: url)
    }
    
    public func isNavigationAllowed() -> Bool {
        return navigationDelegate?.isNavigationAllowed ?? false
    }
    
    public func sebWebViewDidStartLoad() {
        navigationDelegate?.sebWebViewDidStartLoad?()
    }
    
    public func sebWebViewDidFinishLoad() {
        navigationDelegate?.sebWebViewDidFinishLoad?()
//        searchSessionIdentifiers()
    }
    
    private func searchSessionIdentifiers(url: URL) {
        if #available(macOS 10.13, iOS 11.0, *) {
            let httpCookieStore = sebWebView.configuration.websiteDataStore.httpCookieStore
            httpCookieStore.getAllCookies{ cookies in
                let jointCookies = cookies + (HTTPCookieStorage.shared.cookies ?? [])
                self.navigationDelegate?.examine?(jointCookies, for:url)
            }
            return
        }
    }
    
    private func updateKeyJSVariables(_ webView: WKWebView) {
        updateKeyJSVariables(webView) { response, error in
            if let _ = error {
                print(error as Any)
            }
        }
    }

    private func updateKeyJSVariables(_ webView: WKWebView, completionHandler: ((Any?, Error?) -> Void)? = nil) {
        if let url = webView.url {
            let browserExamKey = navigationDelegate?.browserExamKey?(for: url)
            let configKey = navigationDelegate?.configKey?(for: url)
            webView.evaluateJavaScript("SafeExamBrowser.security.browserExamKey = '\(browserExamKey ?? "")';SafeExamBrowser.security.configKey = '\(configKey ?? "")';") { (response, error) in
                completionHandler?(response ?? "", error)
            }
        }
    }
    
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationDelegate?.sebWebViewDidStartLoad?()
    }
    
    public func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
//        searchSessionIdentifiers()
    }
    
    public func webView(_ webView: WKWebView?,
                        didReceive challenge: URLAuthenticationChallenge,
                        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if navigationDelegate == nil {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            navigationDelegate?.webView?(webView, didReceive: challenge, completionHandler: completionHandler)
        }
    }
    
    public func webView(_ webView: WKWebView,
                        didCommit navigation: WKNavigation) {
        setPageZoom()
        setTextSize()
        updateKeyJSVariables(webView)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        navigationDelegate?.sebWebViewDidFinishLoad?()
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var newTab = false
        if navigationAction.targetFrame == nil {
            newTab = true;
        }
        guard let navigationActionPolicy = self.navigationDelegate?.decidePolicy?(for: navigationAction, newTab: newTab) else {
            decisionHandler(.cancel)
            return
        }
        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let callDecisionHandler:() -> () = {
//            DDLogDebug("navigationActionPolicy: \(navigationActionPolicy)")
            if navigationActionPolicy == SEBNavigationActionPolicyAllow {
                decisionHandler(.allow)
            } else if navigationActionPolicy == SEBNavigationActionPolicyCancel {
                decisionHandler(.cancel)
            } else if navigationActionPolicy == SEBNavigationActionPolicyDownload {
                // This case should not happen in the current implementation
                decisionHandler(.cancel)
            }
        }

        if navigationActionPolicy == SEBNavigationActionPolicyAllow && !url.hasDirectoryPath {
            webView.evaluateJavaScript("document.querySelector('[href=\"" + url.absoluteString + "\"]').download") {(result, error) in
                self.downloadFilename = result as? String
                if !(self.downloadFilename ?? "").isEmpty {
//                    DDLogInfo("Link to resource '\(String(describing: self.downloadFilename))' had the 'download' attribute, it will be downloaded instead of displayed.")
                    if ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 11 {
                        if #available(macOS 10.13, iOS 11.0, *) {
                            let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
                            httpCookieStore.getAllCookies{ cookies in
                                self.navigationDelegate?.downloadFile?(from: url, filename: self.downloadFilename!, cookies: cookies)
                                self.downloadFilename = nil
                            }
                            decisionHandler(.cancel)
                            return
                        }
                    }
                }
                callDecisionHandler()
            }
            return
        }
        callDecisionHandler()
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        DDLogDebug("decidePolicyFor navigationResponse")
        
        let decidePolicyWithCookies:([HTTPCookie]) -> () = { cookies in
            guard let url = navigationResponse.response.url else {
                decisionHandler(.cancel)
                return
            }
            let canShowMIMEType = navigationResponse.canShowMIMEType
            let isForMainFrame = navigationResponse.isForMainFrame
            let mimeType = navigationResponse.response.mimeType
            let suggestedFilename = navigationResponse.response.suggestedFilename

            guard let navigationResponsePolicy = self.navigationDelegate?.decidePolicy?(forMIMEType: mimeType, url: url, canShowMIMEType: canShowMIMEType, isForMainFrame: isForMainFrame, suggestedFilename: suggestedFilename, cookies: cookies) else {
                decisionHandler(.cancel)
                return
            }
            
            if let response = navigationResponse.response as? HTTPURLResponse,
                  let url = response.url,
                  response.statusCode == 200,
                  let headers = response.allHeaderFields as? [String: String] {
                self.navigationDelegate?.examineHeaders?(headers, for: url)
            }
            
            if (self.downloadFilename ?? "").isEmpty {
                self.downloadFilename = self.getFileNameFromResponse(navigationResponse.response)
            }

            if (!(self.downloadFilename ?? "").isEmpty || navigationResponsePolicy == SEBNavigationActionPolicyDownload) && !self.downloadingSEBConfig {
                var filename = self.downloadFilename ?? ""
                if filename.isEmpty {
                    filename = suggestedFilename ?? ""
                }
                let isPDF = filename.hasSuffix(".pdf")
                let downloadPDFFiles = self.navigationDelegate!.downloadPDFFiles
                if !isPDF || isPDF && downloadPDFFiles == true {
    //                DDLogInfo("Link to resource '\(filename)' had the 'download' attribute or the header 'Content-Disposition': 'attachment; filename=...', it will be downloaded instead of displayed.")
                    decisionHandler(.cancel)
                    self.navigationDelegate?.downloadFile?(from: url, filename: filename, cookies: cookies)
                    self.downloadFilename = nil
                    return

                }
//                DDLogDebug("Filename '\(filename)' of resource to download determined using the 'download' attribute or the header 'Content-Disposition': 'attachment; filename=...'. Property suggestedFilename from WKNavigationResponse: '\(suggestedFilename ?? "<empty>")'")
            } else {
//                DDLogDebug("downloadFilename: \(String(describing: self.downloadFilename)), downloadingSEBConfig: \(self.downloadingSEBConfig)")
            }
            
            if navigationResponsePolicy == SEBNavigationResponsePolicyAllow {
                decisionHandler(.allow)
            } else if navigationResponsePolicy == SEBNavigationResponsePolicyCancel {
                decisionHandler(.cancel)
            }
        }

        if #available(macOS 10.13, iOS 11.0, *) {
            let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
            httpCookieStore.getAllCookies{ cookies in
                decidePolicyWithCookies(cookies)
            }
        } else {
            decidePolicyWithCookies([])
        }
    }
    
    private func getFileNameFromResponse(_ response:URLResponse) -> String {
        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            if let disposition = headers["Content-Disposition"] as? String {
                let components = disposition.components(separatedBy: ";")
                if components.count > 1 {
                    let innerComponents = components[1].components(separatedBy: "=")
                    if innerComponents.count > 1 {
                        if innerComponents[0].contains("filename") {
                            let filename = innerComponents[1]
                            return filename.replacingOccurrences(of: "\"", with: "")
                        }
                    }
                }
            }
        }
        return ""
    }
    
    public func sebWebViewDidFailLoadWithError(_ error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
    }
    
    public func decidePolicyForNavigationAction(with navigationAction: WKNavigationAction, newTab: Bool) -> SEBNavigationActionPolicy {
        return (navigationDelegate?.decidePolicy?(for: navigationAction, newTab: newTab))!
    }
    
    public func sebWebViewDidUpdateTitle(_ title: String?) {
        navigationDelegate?.sebWebViewDidUpdateTitle?(title)
    }
    
    public func sebWebViewDidUpdateProgress(_ progress: Double) {
        navigationDelegate?.sebWebViewDidUpdateProgress?(progress)
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        navigationDelegate?.webViewDidClose?(webView)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            _ = navigationDelegate?.decidePolicy?(for: navigationAction, newTab: true)
        }
        return nil
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptAlertPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptConfirmPanelWithMessage: message, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String) -> Void) {
        navigationDelegate?.webView?(webView, runJavaScriptTextInputPanelWithPrompt: prompt, defaultText: defaultText, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    public func webView(_ webView: WKWebView?, runOpenPanelWithParameters parameters: Any, initiatedByFrame frame: WKFrameInfo?, completionHandler: @escaping ([URL]) -> Void) {
        navigationDelegate?.webView?(webView, runOpenPanelWithParameters: parameters, initiatedByFrame: frame, completionHandler: completionHandler)
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
    
    public func backgroundTintStyle () -> SEBBackgroundTintStyle {
        return navigationDelegate?.backgroundTintStyle?() ?? SEBBackgroundTintStyleDark
    }
    
    public func storePasteboard() {
        self.navigationDelegate?.storePasteboard?()
    }
    
    public func restorePasteboard() {
        self.navigationDelegate?.restorePasteboard?()
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

//@available(macOS 11.3, iOS 14.5, *)
//extension SEBAbstractModernWebView: WKDownloadDelegate {
//    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
//        let temporaryDir = NSTemporaryDirectory()
//        let fileName = temporaryDir + "/" + suggestedFilename
//        let url = URL(fileURLWithPath: fileName)
//        fileDestinationURL = url
//        completionHandler(url)
//    }
//
//    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
//        print("download failed \(error)")
//    }
//
//    public func downloadDidFinish(_ download: WKDownload) {
//        print("download finish")
//        if let url = fileDestinationURL {
//            self.delegate.fileDownloadedAtURL(url: url)
//        }
//    }
//}
