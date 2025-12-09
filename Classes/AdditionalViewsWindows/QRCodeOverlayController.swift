//
//  QRCodeOverlayController.swift
//  Safe Exam Browser
//
//  Created by Daniel Schneider on 01.12.2025.
//

import Foundation

@objc public protocol QRCodeOverlayControllerDelegate {
    func openLockModalWindows()
    func closeLockModalWindows()
}

@objc public class QRCodeOverlayController: NSObject, NSWindowDelegate {
    
    private var qrCodeOverlayControllerDelegate: QRCodeOverlayControllerDelegate?
    private var qrCodeOverlayPanel: HUDPanel?
    
    @objc init(delegate: QRCodeOverlayControllerDelegate? = nil) {
        self.qrCodeOverlayControllerDelegate = delegate
    }
    
    @objc func showQRCode(pngData: Data?) -> Bool {
        if qrCodeOverlayPanel != nil {
            hideQRConfig()
        }
        var imageWidth = 300.0
        var imageHeigth = 300.0
        var qrCodeView: NSView
        if (pngData != nil) {
            guard let qrCodeImage = NSImage.init(data: pngData!) else {
                return false
            }
            imageWidth = qrCodeImage.size.width;
            imageHeigth = qrCodeImage.size.height;
            let frameRect = NSMakeRect(0, 0, imageWidth, imageHeigth);
            qrCodeView = SEBNSImageView(frame: frameRect, image: qrCodeImage) //alloc] initWithFrame:frameRect image:qrCodeImage];
        } else {
            qrCodeView = overlayViewForLabel(text: String("Config Too Large for QR Code"))
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
        qrCodeOverlayPanel?.sharingType = NSWindow.SharingType.readOnly
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
        overlayViewCloseButton.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize) //boldSystemFontOfSize:[NSFont systemFontSize]];
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
