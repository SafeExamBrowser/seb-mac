//
//  SEBOSXWKWebViewController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 10.08.21.
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

public class SEBOSXWKWebViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, SEBAbstractBrowserControllerDelegate {
    
    weak public var navigationDelegate: SEBAbstractWebViewNavigationDelegate?
    
    public var sebWebView : SEBOSXWKWebView?
    
    public var privateClipboardEnabled = false
    public var allowDictionaryLookup = false
    public var allowPDFPlugIn = false

    public var scrollLockActive = false
    
    private var zoomScale : CGFloat?

    private var urlFilter : SEBURLFilter?
    
    public func contentView() -> NSView? {
        return self.contentView()
    }
    
    public override func loadView() {
        if sebWebView == nil {
            let webViewConfiguration = navigationDelegate?.wkWebViewConfiguration
            DDLogDebug("WKWebViewConfiguration \(String(describing: webViewConfiguration))")
            sebWebView = SEBOSXWKWebView.init(frame: .zero, configuration: webViewConfiguration!)
            sebWebView?.sebOSXWebViewController = self
            
//            try? sebWebView?.swizzleMethod(NSSelectorFromString("copy:"), withSelector: #selector(newCopy(_:)))
//            try? sebWebView?.swizzleMethod(NSSelectorFromString("cut:"), withSelector: #selector(newCut(_:)))
//            try? sebWebView?.swizzleMethod(NSSelectorFromString("paste:"), withSelector: #selector(newPaste(_:)))
        }
        sebWebView?.autoresizingMask = [.width, .height]
        sebWebView?.translatesAutoresizingMaskIntoConstraints = true
        sebWebView?.uiDelegate = self
        sebWebView?.navigationDelegate = self
        
        sebWebView?.customUserAgent = navigationDelegate?.customSEBUserAgent
        urlFilter = SEBURLFilter.shared()
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
        self.allowDictionaryLookup = allowDictionaryLookup
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
    
    public func reload() {
        sebWebView?.reload()
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
    
    public func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        DDLogError("[SEBOSXWKWebViewController webViewWebContentProcessDidTerminate:\(webView)]")
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
        let classType: AnyClass! = object_getClass(self)
        return class_getInstanceMethod(classType, selector)
    }
}


public class SEBOSXWKWebView: WKWebView {
    
    weak public var sebOSXWebViewController: SEBOSXWKWebViewController?
        
    @available(macOS 10.12.2, *)
    public override func makeTouchBar() -> NSTouchBar? {
        return nil
    }
    
    public override func quickLook(with event: NSEvent) {
        if sebOSXWebViewController!.allowDictionaryLookup {
            super.quickLook(with: event)
            DDLogInfo("Dictionary look-up was used! [SEBOSXWKWebView quickLookWithEvent:]")
        } else {
            DDLogInfo("Dictionary look-up was blocked! [SEBOSXWKWebView quickLookWithEvent:]")
        }
    }
    
    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if sebOSXWebViewController!.privateClipboardEnabled {
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
        if sebOSXWebViewController!.privateClipboardEnabled {
            delayWithSeconds(0.1) {
                self.sebOSXWebViewController!.storePasteboard()
            }
        }
    }

    @objc public func privateCut(_ sender: Any?) {
        super.perform(NSSelectorFromString("cut:"), with: sender)
        if sebOSXWebViewController!.privateClipboardEnabled {
            delayWithSeconds(0.1) {
                self.sebOSXWebViewController!.storePasteboard()
            }
        }
    }

    @objc public func privatePaste(_ sender: Any?) {
        if sebOSXWebViewController!.privateClipboardEnabled {
            self.sebOSXWebViewController!.restorePasteboard()
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
