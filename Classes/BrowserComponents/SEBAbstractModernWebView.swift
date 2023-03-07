//
//  SEBAbstractModernWebView.swift
//  SafeExamBrowser
//
//  Created by Daniel R. Schneider on 03.03.21.
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
import PDFKit

@objc public class SEBAbstractModernWebView: NSObject, SEBAbstractBrowserControllerDelegate, SEBAbstractWebViewNavigationDelegate, WKScriptMessageHandler {
    
    private var sebWebView: WKWebView {
        let webView = nativeWebView() as! WKWebView
        return webView
    }
    
    private let defaultPageZoom = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableZoomPage") ? UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_defaultPageZoomLevel") : WebViewDefaultPageZoom
    private let defaultTextZoom = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableZoomText") ? UserDefaults.standard.secureDouble(forKey: "org_safeexambrowser_SEB_defaultTextZoomLevel") : WebViewDefaultTextZoom
    private let browserMediaCaptureCamera = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_browserMediaCaptureCamera")
    private let browserMediaCaptureMicrophone = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_browserMediaCaptureMicrophone")
    public let browserMediaCaptureScreen = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_browserMediaCaptureScreen")
    public let zoomPageSupported = true
    public var pageZoom = WebViewDefaultPageZoom
    private var previousZoomLevel = WebViewDefaultPageZoom
    private var textZoom = WebViewDefaultTextZoom
    private var controlSpellCheckCode = ""
    private var previousSearchText = ""

    private var downloadFilename: String?
    private var forceDownload = false
    public var downloadingSEBConfig = false
    fileprivate var fileDownloadDestinationURL: URL?
    
    public var wkWebViewConfiguration: WKWebViewConfiguration {
        let webViewConfiguration = navigationDelegate?.wkWebViewConfiguration
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
        
        let jsDocumentEndCode = """
    var elements = document.body.querySelectorAll('a[href]:not([disabled]), button:not([disabled]), textarea:not([disabled]), input[type="text"]:not([disabled]), input[type="radio"]:not([disabled]), input[type="checkbox"]:not([disabled]), select:not([disabled]), details:not([disabled]), summary:not([disabled])');
    if (elements[0]) {
        elements[0].addEventListener('blur', (event) => {
            window.webkit.messageHandlers.firstElementBlured.postMessage(event.target.outerHTML);
        }, true);
        elements[elements.length - 1].addEventListener('blur', (event) => {
            window.webkit.messageHandlers.lastElementBlured.postMessage(event.target.outerHTML);
        }, true);
    }
"""
        let jsDocumentEndScript = WKUserScript(source: jsDocumentEndCode, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        userContentController.addUserScript(jsDocumentEndScript)
        
        if let pageJavaScriptCode = navigationDelegate?.pageJavaScript {
            let pageModifyUserScript = WKUserScript(source: pageJavaScriptCode, injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
            userContentController.addUserScript(pageModifyUserScript)
            let allowSpellCheck = navigationDelegate?.allowSpellCheck ?? false
            controlSpellCheckCode = "SEB_AllowSpellCheck(\(allowSpellCheck ? "true" : "false"))"
            let controlSpellCheckUserScript = WKUserScript(source: controlSpellCheckCode, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
            userContentController.addUserScript(controlSpellCheckUserScript)
        }
        userContentController.add(self, name: "updateKeys")
        userContentController.add(self, name: "firstElementBlured")
        userContentController.add(self, name: "lastElementBlured")
        webViewConfiguration?.userContentController = userContentController
        let allowContentJavaScript = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableJavaScript")
        if #available(macOS 11.0, iOS 14.0, *) {
            webViewConfiguration?.defaultWebpagePreferences.allowsContentJavaScript = allowContentJavaScript
        } else {
            webViewConfiguration?.preferences.javaScriptEnabled = allowContentJavaScript
        }
        webViewConfiguration?.preferences.javaScriptCanOpenWindowsAutomatically = !UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_blockPopUpWindows")
#if os(macOS)
        if #available(macOS 10.12.3, *) {
            webViewConfiguration?.preferences.tabFocusesLinks = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_tabFocusesLinks")
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
        if message.name == "firstElementBlured" {
            let parameter = message.body as? String
            DDLogVerbose("First DOM Element deselected: \(parameter as Any)")
            self.navigationDelegate?.firstDOMElementDeselected?()
        }
        if message.name == "lastElementBlured" {
            let parameter = message.body as? String
            DDLogVerbose("Last DOM Element deselected: \(parameter as Any)")
            self.navigationDelegate?.lastDOMElementDeselected?()
        }
    }
    
    public var customSEBUserAgent: String {
        return navigationDelegate?.customSEBUserAgent ?? ""
    }
    
    @objc public var browserControllerDelegate: SEBAbstractBrowserControllerDelegate?
    @objc weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?

    private var firstLoad = true

    @objc public init(delegate: SEBAbstractWebViewNavigationDelegate, configuration: WKWebViewConfiguration?) {
        super.init()
        navigationDelegate = delegate
        initWKWebViewController(configuration: configuration)
        let developerExtrasEnabled = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_allowDeveloperConsole")
        sebWebView.setValue(developerExtrasEnabled, forKey: "allowsRemoteInspection")
        
        pageZoom = defaultPageZoom
        textZoom = defaultTextZoom
    }
    
    public func initWKWebViewController(configuration: WKWebViewConfiguration?) {
#if os(iOS)
        let sebWKWebViewController = SEBiOSWKWebViewController(delegate: self, configuration: configuration)
        self.browserControllerDelegate = sebWKWebViewController
#elseif os(macOS)
        let sebWKWebViewController = SEBOSXWKWebViewController(delegate: self, configuration: configuration)
        self.browserControllerDelegate = sebWKWebViewController
#endif
    }
    
    public func loadView() {
        browserControllerDelegate?.loadView?()
    }
    
    public func didMoveToParentViewController() {
        browserControllerDelegate?.didMoveToParentViewController?()
    }
    
    public func viewDidLayout() {
        browserControllerDelegate?.viewDidLayout?()
    }
    
    public func viewDidLayoutSubviews() {
        browserControllerDelegate?.viewDidLayoutSubviews?()
    }
    
    public func viewWillTransitionToSize() {
        browserControllerDelegate?.viewWillTransitionToSize?()
    }
    
    public func viewDidLoad() {
        browserControllerDelegate?.viewDidLoad?()
    }
    
    public func viewWillAppear() {
        browserControllerDelegate?.viewWillAppear?()
    }
    
    public func viewWillAppear(_ animated: Bool) {
        browserControllerDelegate?.viewWillAppear?(animated)
    }
    
    public func viewDidAppear() {
        browserControllerDelegate?.viewDidAppear?()
    }

    public func viewDidAppear(_ animated: Bool) {
        browserControllerDelegate?.viewDidAppear?(animated)
    }
    
    public func viewWillDisappear() {
        browserControllerDelegate?.viewWillDisappear?()
    }
    
    public func viewWillDisappear(_ animated: Bool) {
        browserControllerDelegate?.viewWillDisappear?(animated)
    }
    
    public func viewDidDisappear() {
        browserControllerDelegate?.viewDidDisappear?()
    }
    
    public func viewDidDisappear(_ animated: Bool) {
        browserControllerDelegate?.viewDidDisappear?(animated)
    }
    
    public func stopMediaPlayback(completionHandler: @escaping () -> Void) {
        let stopMediaScript = "var videos = document.getElementsByTagName('video'); for( var i = 0; i < videos.length; i++ ){videos.item(i).pause()}"
        if #available(macOS 12, iOS 15.0, *) {
            sebWebView.pauseAllMediaPlayback {
                self.sebWebView.closeAllMediaPresentations(completionHandler: completionHandler)
            }
            return
        } else {
            sebWebView.evaluateJavaScript(stopMediaScript, completionHandler: { (response, error) in
                if let _ = error {
                    print(error as Any)
                }
                if #available(macOS 11.3, iOS 14.5, *) {
                    self.sebWebView.closeAllMediaPresentations()
                }
                completionHandler()
            })
            return
        }
    }
    
    public func nativeWebView() -> Any {
        return browserControllerDelegate?.nativeWebView!() as Any
    }
    
    public func closeWKWebView() {
        browserControllerDelegate?.closeWKWebView?()
    }
    
    public func url() -> URL? {
        return browserControllerDelegate?.url?()
    }
    
    public func pageTitle() -> String? {
        return browserControllerDelegate?.pageTitle?()
    }
    
    public func canGoBack() -> Bool {
        return browserControllerDelegate?.canGoBack?() ?? false
    }
    
    public func canGoForward() -> Bool {
        return browserControllerDelegate?.canGoForward?() ?? false
    }
    
    public func goBack() {
        browserControllerDelegate?.goBack?()
    }
    
    public func goForward() {
        browserControllerDelegate?.goForward?()
    }
    
    public func clearBackForwardList() {
        browserControllerDelegate?.clearBackForwardList?()
    }
    
    public func reload() {
        previousZoomLevel = 1
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince:NSDate.distantPast, completionHandler:{
            if let url = self.sebWebView.url {
                self.load(url)
            } else {
                if let currentPageURL = self.navigationDelegate?.currentURL {
                    if currentPageURL != nil {
                        self.load(currentPageURL!)
                    }
                }
            }
        })
    }
    
    public func load(_ url: URL) {
        browserControllerDelegate?.load?(url)
    }
    
    public func stopLoading() {
        browserControllerDelegate?.stopLoading?()
    }
    
    public func focusFirstElement() {
        sebWebView.evaluateJavaScript("SEB_FocusFirstElement()")
    }

    public func focusLastElement() {
        sebWebView.evaluateJavaScript("SEB_FocusLastElement()")
    }

    fileprivate func setPageZoom() {
        if (pageZoom <= WebViewMaxPageZoom && pageZoom >= WebViewMinPageZoom) {
            if #available(macOS 11.0, iOS 14.0, *) {
#if os(iOS)
                if pageZoom == 1 && previousZoomLevel == 1 {
                    return
                }
                let zoomLevelDelta = pageZoom / previousZoomLevel
                if pageZoom >= 1 && !(pageZoom == 1 && previousZoomLevel < 1) {
                    let iOSPageZoom = (abs((pageZoom - 1) / (WebViewMaxPageZoom - 1) - 1) * (1 - WebViewMinPageZoom)) + WebViewMinPageZoom
                    sebWebView.pageZoom = iOSPageZoom
                    if zoomLevelDelta != 1 {
                        let js = """
                                var images = document.images;
                                for (var i = 0, max = images.length; i < max; i++)
                                {
                                    var width = images[i].width;
                                    var height = images[i].height;
                                    images[i].width = width * \(zoomLevelDelta);
                                    images[i].height = height * \(zoomLevelDelta);
                                }
    """
                        sebWebView.evaluateJavaScript(js) { (response, error) in
                            if let _ = error {
                                    print(error as Any)
                            }
                            self.browserControllerDelegate?.updateZoomScale?(iOSPageZoom)
                        }
                    }
                } else {
                    if pageZoom == 1 && previousZoomLevel < 1 {
                        reload()
                    } else {
                        let js = "document.documentElement.style.zoom = '\(pageZoom)'; \(textZoomJS(zoomLevel: pageZoom))"
                        sebWebView.evaluateJavaScript(js) { (response, error) in
                            if let _ = error {
                                    print(error as Any)
                            }
                            self.browserControllerDelegate?.updateZoomScale?(self.pageZoom)
                        }
                    }
                }
                previousZoomLevel = pageZoom
#else
                sebWebView.pageZoom = pageZoom
#endif
            } else {
                let js = "document.documentElement.style.zoom = '\(pageZoom)'"
                sebWebView.evaluateJavaScript(js) { (response, error) in
                    if let _ = error {
                        print(error as Any)
                    }
                    self.browserControllerDelegate?.updateZoomScale?(self.pageZoom)
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
#if os(iOS)
        setPageZoom()
        reload()
#else
        setPageZoom()
#endif
    }
    
    private func textZoomJS(zoomLevel: Double) -> String {
        let fontSize = Int(WebViewDefaultTextSize * zoomLevel)
        var jsZoomLevel = zoomLevel
        if zoomLevel > 1 {
            jsZoomLevel = ((zoomLevel-1)/5)+1
        }
        return """
                function zoomTextForTagName(tag) {
                    var elements = document.getElementsByTagName(tag);
                    for (var i = 0, max = elements.length; i < max; i++)
                    {
                        var computedFontSize = parseInt(window.getComputedStyle(elements[i]).fontSize, 10);
                        computedFontSize *= \(jsZoomLevel);
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
#if os(iOS)
        if (pageZoom == 1 && textZoom != 1 && textZoom <= WebViewMaxTextZoom && textZoom >= WebViewMinTextZoom) {
            let js = textZoomJS(zoomLevel: textZoom)
            sebWebView.evaluateJavaScript(js) { (response, error) in
                if let _ = error {
                    print(error as Any)
                }
            }
        }
#else
        typealias setTextZoomMethod = @convention(c) (NSObject, Selector, Double) -> Void
        
        let selector = NSSelectorFromString("_setTextZoomFactor:")
        let methodIMP = sebWebView.method(for: selector)
        let method = unsafeBitCast(methodIMP, to: setTextZoomMethod.self)
        let _ = method(sebWebView, selector, textZoom)
#endif
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
    
    public func searchText(_ textToSearch: String?, backwards: Bool, caseSensitive: Bool)
    {
        guard let searchText = textToSearch else {
            previousSearchText = ""
            self.navigationDelegate?.searchTextMatchFound?(false)
            return
        }
#if os(macOS)
        if let url = self.sebWebView.url, url.pathExtension.caseInsensitiveCompare(filenameExtensionPDF) == .orderedSame {
            if #available(macOS 11, iOS 14, *) {
                let findConfiguration = WKFindConfiguration.init()
                findConfiguration.backwards = backwards
                findConfiguration.caseSensitive = caseSensitive
                findConfiguration.wraps = true
                sebWebView.find(searchText, configuration: findConfiguration) { findResult in
                    let matchFound = findResult.matchFound
                    if !matchFound {
                        let js = "window.getSelection().removeAllRanges();"
                        self.sebWebView.evaluateJavaScript(js)
                    }
                    self.navigationDelegate?.searchTextMatchFound?(matchFound)
                }
                return
            }
        }
#endif
        if searchText.isEmpty {
            previousSearchText = searchText
            sebWebView.evaluateJavaScript("SEB_RemoveAllHighlights()")
            self.navigationDelegate?.searchTextMatchFound?(false)
        } else {
            // Check if we're dealing with a PDF
//            if let pdfView = searchForPDFView(view: sebWebView) {
//                print(pdfView as Any)
//            }
            if textToSearch == previousSearchText {
                if backwards {
                    self.sebWebView.evaluateJavaScript("SEB_SearchPrevious()")
                } else {
                    self.sebWebView.evaluateJavaScript("SEB_SearchNext()")
                }
                self.navigationDelegate?.searchTextMatchFound?(true)
            } else {
                previousSearchText = searchText
                let searchString = "SEB_HighlightAllOccurencesOfString('\(searchText)')"
                sebWebView.evaluateJavaScript(searchString) { result, error in
                    if backwards {
                        self.sebWebView.evaluateJavaScript("SEB_SearchPrevious()")
                    } else {
                        self.sebWebView.evaluateJavaScript("SEB_SearchNext()")
                    }
                    self.sebWebView.evaluateJavaScript("SEB_SearchResultCount") { (result, error) in
                        if error == nil {
                            if result != nil {
                                let count = result as! Int
                                if count > 0 {
                                    self.navigationDelegate?.searchTextMatchFound?(true)
                                    return
                                }
                            }
                        }
                        self.sebWebView.evaluateJavaScript("SEB_RemoveAllHighlights()")
                        self.navigationDelegate?.searchTextMatchFound?(false)
                    }
                }
            }
        }
    }
    
    private func searchForPDFView(view: Any?) -> (PDFView?) {
#if os(macOS)
        guard let subviews = (view as! NSView?)?.subviews else {
            return nil
        }
        #else
        guard let subviews = (view as! UIView?)?.subviews else {
            return nil
        }
        #endif

        for subview in subviews {
            print(subview as Any)
            if let pdfView = subview as? PDFView {
                return pdfView
            } else if subview.subviews.count > 0 {
                if let foundPDFView = searchForPDFView(view: subview) {
                    return foundPDFView
                }
            }
        }
        return nil
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
        browserControllerDelegate?.toggleScrollLock?()
    }
    
    public func isScrollLockActive() -> Bool {
        return browserControllerDelegate?.isScrollLockActive?() ?? false
    }
    
    public func setPrivateClipboardEnabled(_ privateClipboardEnabled: Bool) {
        browserControllerDelegate?.setPrivateClipboardEnabled?(privateClipboardEnabled)
    }
    
    public func setAllowDictionaryLookup(_ allowDictionaryLookup: Bool) {
        browserControllerDelegate?.setAllowDictionaryLookup?(allowDictionaryLookup)
    }
    
    public func setAllowPDFPlugIn(_ allowPDFPlugIn: Bool) {
        browserControllerDelegate?.setAllowPDFPlugIn?(allowPDFPlugIn)
    }
    
    public func sessionTaskDidCompleteSuccessfully(_ task: URLSessionTask) {
        browserControllerDelegate?.sessionTaskDidCompleteSuccessfully?(task)
    }
    
    /// SEBAbstractWebViewNavigationDelegate Methods

    public func setLoading(_ loading: Bool) {
        navigationDelegate?.setLoading?(loading)
    }
    
    public func setCanGoBack(_ canGoBack: Bool, canGoForward: Bool) {
        navigationDelegate?.setCanGoBack?(canGoBack, canGoForward: canGoForward)
    }
    
    public func openNewTab(with url: URL?, configuration: WKWebViewConfiguration?) -> SEBAbstractWebView {
        return (navigationDelegate?.openNewTab?(with: url, configuration: configuration))!
    }

    public func examine(_ cookies: [HTTPCookie], url: URL) {
        navigationDelegate?.examine?(cookies, for: url)
    }
    
    public func isNavigationAllowed() -> Bool {
        return navigationDelegate?.isNavigationAllowed ?? false
    }
    
    public var isAACEnabled: Bool {
        return navigationDelegate?.isAACEnabled ?? false
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
        } else {
            self.navigationDelegate?.examine?(HTTPCookieStorage.shared.cookies ?? [], for:url)
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
    
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationDelegate?.sebWebViewDidFailLoadWithError?(error)
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
        previousZoomLevel = 1
        setPageZoom()
        setTextSize()
        updateKeyJSVariables(webView)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation) {
        navigationDelegate?.sebWebViewDidFinishLoad?()
        sebWebView.evaluateJavaScript(controlSpellCheckCode)
    }
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        reload()
    }

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        var newTab = false
        if navigationAction.targetFrame == nil {
            newTab = true
        }
        var navigationActionPolicy = SEBNavigationActionPolicyCancel

        guard let url = navigationAction.request.url else {
            decisionHandler(.cancel)
            return
        }

        let allowDownloads = self.navigationDelegate?.allowDownUploads ?? false
        
        let callDecisionHandler:() -> () = {
            if navigationActionPolicy == SEBNavigationActionPolicyAllow {
                decisionHandler(.allow)
            } else if navigationActionPolicy == SEBNavigationActionPolicyCancel {
                decisionHandler(.cancel)
            } else if navigationActionPolicy == SEBNavigationActionPolicyDownload {
                // This case should not happen in the current implementation
                decisionHandler(.cancel)
            } else if navigationActionPolicy == SEBNavigationActionPolicyJSOpen {
                decisionHandler(.allow)
            }
        }

        let proceedHandler:() -> () = {
            if self.downloadFilename != nil && !(self.downloadFilename ?? "").isEmpty {
                // On iOS we currently don't support donwloading PDFs -> display it
                var displayPDF = ((self.downloadFilename ?? "") as NSString).pathExtension.caseInsensitiveCompare(filenameExtensionPDF) == .orderedSame
#if os(macOS)
                if displayPDF {
                    // A link to a PDF file with the "download" parameter was invoked
                    // if downloading is not allowed, we display the PDF in the browser
                    displayPDF = !allowDownloads
                }
#endif
                if displayPDF {
                    newTab = true
                }
            }
            let newNavigationPolicy = self.navigationDelegate?.decidePolicy?(for: navigationAction, newTab: newTab, configuration:nil, downloadFilename:self.downloadFilename)
            navigationActionPolicy = newNavigationPolicy?.policy ?? SEBNavigationActionPolicyCancel

            if navigationActionPolicy != SEBNavigationActionPolicyCancel {
                if #available(macOS 11.3, iOS 14.5, *) {
                    if navigationAction.shouldPerformDownload {
                        if allowDownloads {
                            decisionHandler(.download)
                        } else {
                            self.navigationDelegate?.showAlertNotAllowedDownUploading?(false)
                            decisionHandler(.cancel)
                        }
                        return
                    }
                } else {
                    // Fallback on earlier versions
                }
                if !(self.downloadFilename ?? "").isEmpty {
                    if allowDownloads {
                        DDLogInfo("Link to resource '\(String(describing: self.downloadFilename))' had the 'download' attribute, it will be downloaded instead of displayed.")
                        self.forceDownload = false
                        if #available(macOS 10.13, iOS 11.0, *) {
                            let httpCookieStore = webView.configuration.websiteDataStore.httpCookieStore
                            httpCookieStore.getAllCookies{ cookies in
                                self.navigationDelegate?.downloadFile?(from: url, filename: self.downloadFilename ?? "", cookies: cookies)
                                self.downloadFilename = nil
                            }
                            decisionHandler(.cancel)
                            return
                        } else {
                            decisionHandler(.cancel)
                            self.navigationDelegate?.downloadFile?(from: url, filename: self.downloadFilename ?? "", cookies: HTTPCookieStorage.shared.cookies ?? [])
                            self.downloadFilename = nil
                            return
                        }
                    } else {
                        self.navigationDelegate?.showAlertNotAllowedDownUploading?(false)
                        decisionHandler(.cancel)
                        return
                    }
                }
            } else {
                DDLogDebug("Navigation action policy for URL \(url) was 'cancel'")
            }
            callDecisionHandler()
        }

        if #available(macOS 11.3, iOS 14.5, *) {
            self.downloadFilename = nil
            proceedHandler()
        } else {
            if !url.hasDirectoryPath && (allowDownloads || (url.pathExtension.caseInsensitiveCompare(filenameExtensionPDF) == .orderedSame && (self.downloadFilename ?? "").isEmpty)) {
                webView.evaluateJavaScript("document.querySelector('[href=\"" + url.absoluteString + "\"]')?.download") {(result, error) in
                    if error == nil {
                        self.downloadFilename = result as? String
                        if !(self.downloadFilename ?? "").isEmpty {
                            DDLogDebug("'download' attribute found with filename '\(String(describing: self.downloadFilename))'")
                            self.forceDownload = true
                        }
                    } else {
                        DDLogDebug("Attempting to get 'download' attribute from DOM failed with error '\(String(describing: error))'")
                        self.downloadFilename = nil
                    }
                    proceedHandler()
                }
            } else {
                self.downloadFilename = nil
                proceedHandler()
            }
        }
    }
    
    public func webView(_ webView: WKWebView,
                        decidePolicyFor navigationResponse: WKNavigationResponse,
                        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
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
                let isPDF = (filename as NSString).pathExtension.caseInsensitiveCompare(filenameExtensionPDF) == .orderedSame
                let downloadPDFFiles = self.navigationDelegate?.downloadPDFFiles
                if !isPDF || isPDF && downloadPDFFiles == true || isPDF && self.forceDownload {
                    self.forceDownload = false
                    DDLogInfo("Link to resource '\(filename)' had the 'download' attribute or the header 'Content-Disposition': 'attachment; filename=...', it will be downloaded instead of displayed.")
                    decisionHandler(.cancel)
                    self.navigationDelegate?.downloadFile?(from: url, filename: filename, cookies: cookies)
                    self.downloadFilename = nil
                    return

                }
                DDLogDebug("Filename '\(filename)' of resource to download determined using the 'download' attribute or the header 'Content-Disposition': 'attachment; filename=...'. Property suggestedFilename from WKNavigationResponse: '\(suggestedFilename ?? "<empty>")'")
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
            decidePolicyWithCookies(HTTPCookieStorage.shared.cookies ?? [])
        }
    }
    
    private func getFileNameFromResponse(_ response:URLResponse) -> String {
        if let httpResponse = response as? HTTPURLResponse {
            let headers = httpResponse.allHeaderFields
            if let disposition = headers["Content-Disposition"] as? String {
                let components = disposition.components(separatedBy: ";")
                if components.count > 1 {
                    if components[0].lowercased() == "attachment" {
                        let innerComponents = components[1].components(separatedBy: "=")
                        if innerComponents.count > 1 {
                            if innerComponents[0].lowercased().contains("filename") {
                                let filename = innerComponents[1]
                                forceDownload = true
                                return filename.replacingOccurrences(of: "\"", with: "")
                            }
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
    
    public func decidePolicyForNavigationAction(with navigationAction: WKNavigationAction, newTab: Bool, newWebView: AutoreleasingUnsafeMutablePointer<SEBAbstractWebView?>?) -> SEBNavigationAction {
        guard let newNavigationAction = navigationDelegate?.decidePolicy?(for: navigationAction, newTab: newTab, configuration:nil, downloadFilename:self.downloadFilename) else {
            let newNavigationAction = SEBNavigationAction()
            newNavigationAction.policy = SEBNavigationActionPolicyCancel
            return newNavigationAction
        }
        return newNavigationAction
    }
    
    public func sebWebViewDidUpdateTitle(_ title: String?) {
        navigationDelegate?.sebWebViewDidUpdateTitle?(title)
    }
    
    public func sebWebViewDidUpdateProgress(_ progress: Double) {
        navigationDelegate?.sebWebViewDidUpdateProgress?(progress)
    }
    
    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            let sebWKNavigationAction = SEBWKNavigationAction()
            sebWKNavigationAction.writableNavigationType = navigationAction.navigationType
            let request = navigationAction.request
            sebWKNavigationAction.writableRequest = request
            let newNavigationAction = navigationDelegate?.decidePolicy?(for: sebWKNavigationAction, newTab: true, configuration:configuration, downloadFilename:self.downloadFilename)
            let openedAbstractWebView = newNavigationAction?.openedWebView
#if os(macOS)
            if newNavigationAction?.policy == SEBNavigationActionPolicyJSOpen {
                if openedAbstractWebView != nil { // Excluding special case: Open in same window
                    DDLogInfo("Opened modern WebView after Javascript .open()")
                    let newAbstractWebView = openedAbstractWebView!
                    let newWKWebView = newAbstractWebView.nativeWebView() as? WKWebView
                    return newWKWebView
                }
            }
#endif
        }
        return nil
    }
    
    public func webViewDidClose(_ webView: WKWebView) {
        navigationDelegate?.webViewDidClose?(webView)
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
    
    @available(macOS 12.0, iOS 15.0, *)
    public func permissionDecision(for type: WKMediaCaptureType) -> WKPermissionDecision {
        switch type {
        case .camera:
            return browserMediaCaptureCamera ? .grant : .deny
        case .microphone:
            return browserMediaCaptureMicrophone ? .grant : .deny
        case .cameraAndMicrophone:
            return (browserMediaCaptureCamera && browserMediaCaptureMicrophone) ? .grant : .deny
        @unknown default:
            return .deny
        }
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
    
    public func conditionallyDownloadAndOpenSEBConfig(from url: URL) {
        navigationDelegate?.conditionallyDownloadAndOpenSEBConfig?(from: url)
    }
    
    public func openSEBConfig(from sebConfigData: Data) {
        navigationDelegate?.openSEBConfig?(from: sebConfigData)
    }
}

@available(macOS 11.3, iOS 14.5, *)
extension SEBAbstractModernWebView: WKDownloadDelegate {
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        var filename = suggestedFilename
        let fileManager = FileManager.default
        var fileIndex = 1
        let downloadDirectory = self.navigationDelegate?.downloadPathURL ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let filenameWithoutExtension = (filename as NSString).deletingPathExtension
        let fileExtension = (suggestedFilename as NSString).pathExtension
        while fileManager.fileExists(atPath: downloadDirectory.appendingPathComponent(filename).path) {
            filename = filenameWithoutExtension + "-\(fileIndex)." + fileExtension
            fileIndex+=1
        }
        fileDownloadDestinationURL = downloadDirectory.appendingPathComponent(filename)
        completionHandler(fileDownloadDestinationURL)
    }

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        download.delegate = self
    }

    public func download(_ download: WKDownload, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        webView(sebWebView, didReceive: challenge, completionHandler: completionHandler)
    }
    
    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        DDLogError("Download failed with Error \(error)")
        navigationDelegate?.presentAlert?(withTitle: NSLocalizedString("Download Failed", comment: ""), message: NSLocalizedString(error.localizedDescription, comment: ""))
    }

    public func downloadDidFinish(_ download: WKDownload) {
        if let url = fileDownloadDestinationURL {
            DDLogInfo("File was downloaded at \(url)")
            navigationDelegate?.presentAlert?(withTitle: NSLocalizedString("Download Finished", comment: ""),
                                              message: NSLocalizedString("Saved file '\(url.lastPathComponent)'", comment: ""))
        }
    }
}
