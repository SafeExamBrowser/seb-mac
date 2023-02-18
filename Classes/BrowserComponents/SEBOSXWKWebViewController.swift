//
//  SEBOSXWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 10.08.21.
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
import WebKit

public class SEBOSXWKWebViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, SEBAbstractBrowserControllerDelegate, WKUIDelegatePrivateSEB {
        
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    private var _sebWebView : SEBOSXWKWebView?
    private var webViewConfiguration: WKWebViewConfiguration?
    
    public var sebWebView : SEBOSXWKWebView? {
        if _sebWebView == nil {
            if webViewConfiguration == nil {
                webViewConfiguration = navigationDelegate?.wkWebViewConfiguration
            }
            let fullScreenPossible = navigationDelegate?.isAACEnabled ?? false
            webViewConfiguration?.preferences._setFullScreenEnabled(fullScreenPossible)
//            webViewConfiguration?.preferences._setShouldAllowUserInstalledFonts(false) //ToDo: Test if this controls downloading fonts
//            webViewConfiguration?.preferences._setDeveloperExtrasEnabled(UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_allowDeveloperConsole"))
//            webViewConfiguration?.preferences._setAllowsPicture(inPictureMediaPlayback: fullScreenPossible && UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_mobileAllowPictureInPictureMediaPlayback"))

            DDLogDebug("WKWebViewConfiguration \(String(describing: webViewConfiguration))")
            _sebWebView = SEBOSXWKWebView.init(frame: .zero, configuration: webViewConfiguration!)
            _sebWebView?.sebOSXWebViewController = self
            _sebWebView?.autoresizingMask = [.width, .height]
            _sebWebView?.translatesAutoresizingMaskIntoConstraints = true
            _sebWebView?.uiDelegate = self
            _sebWebView?.navigationDelegate = self
            _sebWebView?.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
            
            _sebWebView?.customUserAgent = navigationDelegate?.customSEBUserAgent
            let enableZoomPage = UserDefaults.standard.secureBool(forKey: "org_safeexambrowser_SEB_enableZoomPage")
            _sebWebView?.allowsMagnification = enableZoomPage
            urlFilter = SEBURLFilter.shared()
        }
        return _sebWebView
    }
    
    public var privateClipboardEnabled = false
    public var allowDictionaryLookup = false
    public var allowPDFPlugIn = false

    public var scrollLockActive = false
    
    private var zoomScale : CGFloat?

    private var urlFilter : SEBURLFilter?
    
    convenience init(delegate: SEBAbstractWebViewNavigationDelegate, configuration: WKWebViewConfiguration?) {
        self.init()
        webViewConfiguration = configuration
        navigationDelegate = delegate
    }
    
    public func closeWKWebView() {
        _sebWebView?.removeObserver(self, forKeyPath: #keyPath(WKWebView.title))
        _sebWebView?.removeFromSuperview()
        _sebWebView = nil
    }
    
    public override func loadView() {
        view = sebWebView!
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            if let title = sebWebView?.title {
                self.navigationDelegate?.sebWebViewDidUpdateTitle?(title)
            }
        }
    }
    
    public override func viewWillAppear() {
        sebWebView?.uiDelegate = self
    }
    
    public override func viewWillDisappear() {
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
    
    public func privateCopy(_ sender: Any) {
        sebWebView?.privateCopy(sender)
    }
    
    public func privateCut(_ sender: Any) {
        sebWebView?.privateCut(sender)
    }
    
    public func privatePaste(_ sender: Any) {
        sebWebView?.privatePaste(sender)
    }
    
    public func toggleScrollLock() {
    }
    
    public func isScrollLockActive() -> Bool {
        return false
    }
    
    public func setPrivateClipboardEnabled(_ privateClipboardEnabled: Bool) {
        self.privateClipboardEnabled = privateClipboardEnabled
    }
    
    public func setAllowDictionaryLookup(_ allowDictionaryLookup: Bool) {
        _sebWebView?.allowsLinkPreview = allowDictionaryLookup
    }
    
    public func setAllowPDFPlugIn(_ allowPDFPlugIn: Bool) {
        self.allowPDFPlugIn = allowPDFPlugIn
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
    
    public func clearBackForwardList() {
        sebWebView?.backForwardList.perform(Selector(("_removeAllItems")))
    }
    
    public func load(_ url: URL) {
        sebWebView?.load(URLRequest.init(url: url))
    }
    
    public func stopLoading() {
        sebWebView?.stopLoading()
    }
 
    public func storePasteboard() {
        self.navigationDelegate?.storePasteboard?()
    }
    
    public func restorePasteboard() {
        self.navigationDelegate?.restorePasteboard?()
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
        DDLogError("[SEBOSXWKWebViewController webViewWebContentProcessDidTerminate:\(webView)]")
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
    
    @available(macOS 10.12, *)
    public func webView(_ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping ([URL]?) -> Void) {
        navigationDelegate?.webView?(webView, runOpenPanelWithParameters: parameters, initiatedByFrame: frame, completionHandler: completionHandler)
    }
    
    @available(macOS 12.0, *)
    public func webView(_ webView: WKWebView, decideMediaCapturePermissionsFor origin: WKSecurityOrigin, initiatedBy frame: WKFrameInfo, type: WKMediaCaptureType) async -> WKPermissionDecision {
        return (navigationDelegate?.permissionDecision?(for: type) ?? .deny)
    }
    
    public func _webView(_ webView: WKWebView, requestUserMediaAuthorizationFor devices: _WKCaptureDevices, url: URL, mainFrameURL: URL, decisionHandler: @escaping (Bool) -> Void) {
        decisionHandler(navigationDelegate?.browserMediaCaptureScreen ?? false)
    }
    
    public func _webView(_ webView: WKWebView, requestDisplayCapturePermissionFor securityOrigin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, withSystemAudio: Bool, decisionHandler: @escaping (WKDisplayCapturePermissionDecision) -> Void) {
        decisionHandler(.screenPrompt)
    }

    @available(macOS 12.0, *)
    public func _webView(_ webView: WKWebView, queryPermission name: String, for origin: WKSecurityOrigin) async -> WKPermissionDecision {
        return .grant
    }
}

@available(macOS 11.3, iOS 14.5, *)
extension SEBOSXWKWebViewController: WKDownloadDelegate {
    
    public func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        navigationDelegate?.download?(download, decideDestinationUsing: response, suggestedFilename: suggestedFilename, completionHandler: completionHandler)
    }

    public func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
        navigationDelegate?.webView?(webView, navigationAction: navigationAction, didBecome: download)
    }

    public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        navigationDelegate?.download?(download, didFailWithError: error, resumeData: resumeData)
    }

    public func downloadDidFinish(_ download: WKDownload) {
        navigationDelegate?.downloadDidFinish?(download)
    }
}

extension NSView {

    /// Find a subview corresponding to the className parameter, recursively.
    public func subviewWithClassName(_ className: String) -> NSView? {
        if NSStringFromClass(type(of: self)) == className {
            return self
        } else {
            let subviews = subviews
            for subview in subviews {
                return subview.subviewWithClassName(className)
            }
        }
        return nil
    }
   
}

extension WKWebView {
    
    public func contentView() -> NSView? {
        return self.subviews.first //subviewWithClassName("WKContentView")
    }
}

extension NSObject {

    enum NSObjectSwizzlingError: Error {
        case originalSelectorNotFound
    }

    @objc public func swizzleMethod(_ currentSelector: Selector, withSelector newSelector: Selector) throws {
        if let currentMethod = self.instanceMethod(for: currentSelector),
            let newMethod = self.instanceMethod(for:newSelector) {
            method_exchangeImplementations(currentMethod, newMethod)
        } else {
            throw NSObjectSwizzlingError.originalSelectorNotFound
        }
    }

    @objc public func instanceMethod(for selector: Selector) -> Method? {
        let classType: AnyClass? = object_getClass(self)
        return class_getInstanceMethod(classType, selector)
    }
}


public class SEBOSXWKWebView: WKWebView {
    
    weak public var sebOSXWebViewController: SEBOSXWKWebViewController?
        
    @available(macOS 10.12.2, *)
    public override func makeTouchBar() -> NSTouchBar? {
        return nil
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if sebOSXWebViewController?.privateClipboardEnabled == true {
            let chars = event.characters
            var status = false
            
            if event.modifierFlags.contains(.command)  {
                if chars == "c" {
                    privateCopy(self)
                    status = true
                }
                if chars == "x" {
                    privateCut(self)
                    status = true
                }
                if chars == "v" {
                    privatePaste(self)
                    status = true
                }
            }
            if status {
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }

    @objc public func privateCopy(_ sender: Any?) {
        super.perform(NSSelectorFromString("copy:"), with: sender)
        if sebOSXWebViewController?.privateClipboardEnabled == true {
            delayWithSeconds(0.1) {
                self.sebOSXWebViewController?.storePasteboard()
            }
        }
    }

    @objc public func privateCut(_ sender: Any?) {
        super.perform(NSSelectorFromString("cut:"), with: sender)
        if sebOSXWebViewController?.privateClipboardEnabled == true {
            delayWithSeconds(0.1) {
                self.sebOSXWebViewController?.storePasteboard()
            }
        }
    }

    @objc public func privatePaste(_ sender: Any?) {
        if sebOSXWebViewController?.privateClipboardEnabled == true {
            self.sebOSXWebViewController?.restorePasteboard()
            delayWithSeconds(0.1) {
                super.perform(NSSelectorFromString("paste:"), with: sender)
                self.delayWithSeconds(0.1) {
                    NSPasteboard.general.clearContents()
                }
            }
        } else {
            super.perform(NSSelectorFromString("paste:"), with: sender)
        }
    }

    func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            completion()
        }
    }
}
