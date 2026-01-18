//
//  QRCodeOverlayController.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 01.12.2025.
//  Copyright (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
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
//  (c) 2010-2025 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
import CocoaLumberjackSwift

@objc public protocol QRCodeOverlayControllerDelegate: AnyObject {
    func openLockModalWindows()
    func closeLockModalWindows()
    func runModalAlert(
        _ alert: NSAlert,
        conditionallyForWindow _window: NSWindow?,
        completionHandler handler: ((NSApplication.ModalResponse) -> Void))
}

@objc public class QRCodeOverlayController: NSObject, NSWindowDelegate {
    
    private var qrCodeOverlayControllerDelegate: QRCodeOverlayControllerDelegate?
    private var qrCodeOverlayPanel: HUDPanel?
    private var displayingCode: Bool = false
    private var cancelDisplayingCode: Bool = false

    @objc init(delegate: QRCodeOverlayControllerDelegate? = nil) {
        super.init()
        self.qrCodeOverlayControllerDelegate = delegate
        dynamicLogLevel = MyGlobals.ddLogLevel()
        NotificationCenter.default.addObserver(self, selector: #selector(self.hideQRCode), name: NSNotification.Name("hideQRCodeOverlay"), object: nil)
    }
    
    @objc func showQRCode(pngData: Data?, isVQRCode: Bool = false) -> Bool {
        if qrCodeOverlayPanel != nil {
            hideQRCode()
        }
        displayingCode = true
        var imageWidth = 340.0
        var imageHeigth = 340.0
        var qrCodeView: SEBNSImageView
        if (pngData != nil) {
            guard let qrCodeImage = NSImage.init(data: pngData!) else {
                return false
            }
            imageWidth = max(imageWidth, qrCodeImage.size.width)
            imageHeigth = max(imageHeigth, qrCodeImage.size.height)
            let frameRect = NSMakeRect(0, 0, imageWidth, imageHeigth)
            qrCodeView = SEBNSImageView(frame: frameRect, image: qrCodeImage)
            qrCodeView.isVQRCode = isVQRCode
        } else {
            qrCodeView = overlayViewForLabel(text: String("Config Too Large for QR Code")) as! SEBNSImageView
        }
        qrCodeView.translatesAutoresizingMaskIntoConstraints = false
        
        qrCodeOverlayControllerDelegate?.openLockModalWindows()
        
        if !cancelDisplayingCode {
            qrCodeOverlayPanel = HUDController.createOverlayPanel(with: qrCodeView, size: CGSizeMake(imageWidth, imageHeigth))
            qrCodeOverlayPanel?.closeOnClick = true
            qrCodeOverlayPanel?.closeOnKeyDown = true
            qrCodeOverlayPanel?.canBecomeKey = true
            qrCodeOverlayPanel?.center()
            qrCodeOverlayPanel?.becomesKeyOnlyIfNeeded = true
            qrCodeOverlayPanel?.level = NSWindow.Level.screenSaver+1
            qrCodeOverlayPanel?.sharingType = NSWindow.SharingType.none
            qrCodeOverlayPanel?.delegate = self
        } else {
            displayingCode = false
            hideQRCode()
        }
        if !cancelDisplayingCode {
            qrCodeOverlayPanel?.makeKeyAndOrderFront(self)
            qrCodeOverlayPanel?.invalidateShadow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.displayingCode = false
            }
        } else {
            displayingCode = false
            hideQRCode()
        }
        
        return true
    }

    func overlayViewForLabel(text: String) -> NSView {
        
        let overlayView = NSView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let overlayViewCloseButton = NSButton(title: text, image: NSImage(named: "SEBBadgeWarning")!, target: self, action: #selector(hideQRCode))
        overlayViewCloseButton.bezelStyle = .regularSquare
        overlayViewCloseButton.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)
        overlayViewCloseButton.translatesAutoresizingMaskIntoConstraints = false
        
        overlayView.addSubview(overlayViewCloseButton)
        overlayViewCloseButton.leadingAnchor.constraint(equalTo: overlayView.leadingAnchor, constant: 7).isActive = true
        overlayViewCloseButton.trailingAnchor.constraint(equalTo: overlayView.trailingAnchor, constant: -7).isActive = true
        overlayViewCloseButton.topAnchor.constraint(equalTo: overlayView.topAnchor, constant: 7).isActive = true
        overlayViewCloseButton.bottomAnchor.constraint(equalTo: overlayView.bottomAnchor, constant: -7).isActive = true
        
        overlayView.clipsToBounds = true
        overlayViewCloseButton.nextResponder = overlayView
        return overlayView
    }
    
    @objc func hideQRCode(notification: NSNotification? = nil) {
        DDLogDebug("QRCodeOverlayController.hideQRCode(): notification received (notification: \(String(describing: notification)) userInfo: \(String(describing: notification?.userInfo)), displaying code: \(displayingCode)")
        
        var userInfoDictionary: [AnyHashable : Any]? = nil
        if let notificationWithUserInfo = notification, let userInfo = notificationWithUserInfo.userInfo {
            userInfoDictionary = userInfo
        }

        if (qrCodeOverlayPanel != nil && (!displayingCode || userInfoDictionary != nil)) {
            DDLogDebug("QRCodeOverlayController.hideQRCode(): closing QR code overlay")
            cancelDisplayingCode = true
            qrCodeOverlayControllerDelegate?.closeLockModalWindows()
            qrCodeOverlayPanel?.orderOut(self)
            qrCodeOverlayPanel = nil
            cancelDisplayingCode = false
        }
        
        if (userInfoDictionary != nil) {
            guard let elapsedSecondsAfterLastClickString = userInfoDictionary?["seconds"] else {
                DDLogDebug("QRCodeOverlayController.hideQRCode(): No 'seconds' key in userInfo dictionary")
                return
            }
            guard let elapsedSecondsAfterLastClick = Int64(elapsedSecondsAfterLastClickString as? String ?? "") else {
                DDLogDebug("QRCodeOverlayController.hideQRCode(): No int number value in 'seconds' key in userInfo dictionary")
                return
            }
            DDLogDebug("QRCodeOverlayController.hideQRCode(): userInfo dictionary contained a 'seconds' key with value \(elapsedSecondsAfterLastClick)")
            if (elapsedSecondsAfterLastClick < 60) {
                DDLogDebug("QRCodeOverlayController.hideQRCode(): Show alert 'Can't show QR code, wait \(60 - elapsedSecondsAfterLastClick) seconds before attempting to show a Verificator QR Code again'")
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("Can't show QR code", comment: "Title of alert 'Can't show QR code'")
                alert.informativeText = NSLocalizedString("For security reasons, wait \(60 - elapsedSecondsAfterLastClick) seconds before attempting to show a Verificator QR Code again", comment: "")
                qrCodeOverlayControllerDelegate?.runModalAlert(alert, conditionallyForWindow: nil, completionHandler: { _ in
                    hideQRCode()
                })
            }
        }
    }
    
    @objc public func windowDidResignKey(_ notification: Notification) {
        hideQRCode()
    }
    
    @objc public func windowWillClose(_ notification: Notification) {
        hideQRCode()
    }
}

