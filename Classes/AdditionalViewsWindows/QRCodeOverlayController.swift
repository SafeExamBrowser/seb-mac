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

@objc public protocol QRCodeOverlayControllerDelegate: AnyObject {
    func openLockModalWindows()
    func closeLockModalWindows()
}

@objc public class QRCodeOverlayController: NSObject, NSWindowDelegate {
    
    private var qrCodeOverlayControllerDelegate: QRCodeOverlayControllerDelegate?
    private var qrCodeOverlayPanel: HUDPanel?
    
    @objc init(delegate: QRCodeOverlayControllerDelegate? = nil) {
        self.qrCodeOverlayControllerDelegate = delegate
    }
    
    @objc func showQRCode(pngData: Data?, isVQRCode: Bool = false) -> Bool {
        if qrCodeOverlayPanel != nil {
            hideQRConfig()
        }
        var imageWidth = 300.0
        var imageHeigth = 300.0
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
        
        qrCodeOverlayPanel = HUDController.createOverlayPanel(with: qrCodeView, size: CGSizeMake(imageWidth, imageHeigth)) // createOverlayPanelWithView:qrCodeView size:CGSizeMake(imageWidth, imageHeigth)];
        qrCodeOverlayPanel?.closeOnClick = true
        qrCodeOverlayPanel?.closeOnKeyDown = true
        qrCodeOverlayPanel?.canBecomeKey = true
        qrCodeOverlayPanel?.center()
        qrCodeOverlayPanel?.becomesKeyOnlyIfNeeded = true
        qrCodeOverlayPanel?.level = NSWindow.Level.screenSaver+1
        qrCodeOverlayPanel?.sharingType = NSWindow.SharingType.none
        qrCodeOverlayPanel?.delegate = self
        qrCodeOverlayPanel?.makeKeyAndOrderFront(self)
        qrCodeOverlayPanel?.invalidateShadow()
        return true
    }

    func overlayViewForLabel(text: String) -> NSView {
        
        let overlayView = NSView()
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        
        let overlayViewCloseButton = NSButton(title: text, image: NSImage(named: "SEBBadgeWarning")!, target: self, action: #selector(hideQRConfig))
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
    
    @objc func hideQRConfig() {
        if (qrCodeOverlayPanel != nil) {
            qrCodeOverlayControllerDelegate?.closeLockModalWindows()
            qrCodeOverlayPanel?.orderOut(self)
            qrCodeOverlayPanel = nil
        }
    }
    
    @objc public func windowDidResignKey(_ notification: Notification) {
        hideQRConfig()
    }
    
    @objc public func windowWillClose(_ notification: Notification) {
        hideQRConfig()
    }
}
