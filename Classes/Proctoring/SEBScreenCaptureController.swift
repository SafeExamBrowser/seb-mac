//
//  SEBScreenCaptureController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.05.24.
//  Copyright (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen
//  Project concept: Thomas Piendl, Daniel R. Schneider, Damian Buechel,
//  Andreas Hefti, Nadim Ritter,
//  Dirk Bauer, Kai Reuter, Tobias Halbherr, Karsten Burger, Marco Lehre,
//  Brigitte Schmucki, Oliver Rahs. French localization: Nicolas Dunand
//
//  ``The contents of this file are subject to the Mozilla Public License
//  Version 2.0 (the "License"); you may not use this file except in
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
//  (c) 2010-2026 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
#if os(iOS)
import MobileCoreServices
#endif
#if os(macOS)
import AppKit
#endif

public class ScreenCaptureController {
    
    public init() {
    }
    
#if os(macOS)
    /// Capture the contents of a specific view using cacheDisplay(in:to:),
    /// which renders from the app's own view hierarchy rather than using
    /// system screen capture APIs (which are blocked by AAC).
    /// The view rendering is dispatched to the main thread since NSView
    /// operations require it, while the image processing runs on the caller's thread.
    public func takeScreenShot(of view: NSView, scale: Double, quantization: ColorQuantization) -> Data? {
        // Capture the bitmap on the main thread
        var cgImage: CGImage?
        let work = {
            cgImage = self.captureBitmapRep(of: view)?.cgImage
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync { work() }
        }
        guard var imageRef = cgImage else {
            return nil
        }
        return processImage(&imageRef, scale: scale, quantization: quantization)
    }

    /// Capture all given windows (ordered back-to-front) and composite them onto a
    /// single image spanning the union of all screens, positioned by each window's
    /// frame and z-order. Used under AAC, where system screen capture returns black.
    /// All view rendering and compositing happens on the main thread (NSView /
    /// NSScreen access requires it); the image processing runs on the caller's thread.
    public func takeScreenShot(ofWindows windows: [NSWindow], scale: Double, quantization: ColorQuantization) -> Data? {
        var cgImage: CGImage?
        let work = {
            cgImage = self.compositeWindows(windows)
        }
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.sync { work() }
        }
        guard var imageRef = cgImage else {
            return nil
        }
        return processImage(&imageRef, scale: scale, quantization: quantization)
    }

    /// Renders a single view into a bitmap via cacheDisplay. Must be called on the main thread.
    private func captureBitmapRep(of view: NSView) -> NSBitmapImageRep? {
        let bounds = view.bounds
        guard bounds.width > 0 && bounds.height > 0 else {
            return nil
        }
        guard let bitmapRep = view.bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        view.cacheDisplay(in: bounds, to: bitmapRep)
        return bitmapRep
    }

    /// Composites the given windows (back-to-front) onto a canvas spanning the union
    /// of all screens. Coordinates are in AppKit screen space (bottom-left origin),
    /// so window frames map directly into the canvas. Must be called on the main thread.
    private func compositeWindows(_ windows: [NSWindow]) -> CGImage? {
        // Canvas = union of all screen frames (global coordinates, bottom-left origin)
        var canvasRect = CGRect.null
        for screen in NSScreen.screens {
            canvasRect = canvasRect.union(screen.frame)
        }
        guard !canvasRect.isNull, canvasRect.width >= 1, canvasRect.height >= 1 else {
            return nil
        }
        let pixelWidth = Int(canvasRect.width.rounded())
        let pixelHeight = Int(canvasRect.height.rounded())

        guard let canvasRep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                               pixelsWide: pixelWidth,
                                               pixelsHigh: pixelHeight,
                                               bitsPerSample: 8,
                                               samplesPerPixel: 4,
                                               hasAlpha: true,
                                               isPlanar: false,
                                               colorSpaceName: .deviceRGB,
                                               bytesPerRow: 0,
                                               bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: canvasRep) else {
            return nil
        }

        let previousContext = NSGraphicsContext.current
        NSGraphicsContext.current = context
        defer { NSGraphicsContext.current = previousContext }

        // Base fill: neutral gray for the area outside SEB's own windows (not
        // capturable under AAC). This also matches AAC's own gray backdrop, so the
        // composite looks more realistic.
        NSColor(white: 0.5, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight)).fill()

        for window in windows {
            guard window.isVisible, window.alphaValue > 0, !window.isMiniaturized else {
                continue
            }
            let frame = window.frame
            guard frame.intersects(canvasRect), frame.width >= 1, frame.height >= 1 else {
                continue
            }
            // Capture the window's frame view (contentView.superview) to include chrome.
            guard let view = window.contentView?.superview ?? window.contentView,
                  let rep = captureBitmapRep(of: view) else {
                continue
            }
            // Map window frame into canvas coordinates (both bottom-left origin).
            let destination = NSRect(x: frame.origin.x - canvasRect.origin.x,
                                     y: frame.origin.y - canvasRect.origin.y,
                                     width: frame.width,
                                     height: frame.height)
            // Clip to rounded corners so the square corners of the captured bitmap
            // don't paint over windows/background behind them (macOS windows have
            // rounded corners). Windows that fill a whole screen are left square.
            let cornerRadius = windowCornerRadius(for: window)
            // Transparent regions of the captured bitmap (e.g. the tiles behind
            // borderless dock buttons like Reload/Quit, which paint no background)
            // would otherwise show the desktop base gray or, worse, be composited over
            // black by the later greyscale step (black boxes). Fill the window's rect
            // with its own opaque background color first (e.g. the dock bar color) so
            // those regions match the window, then draw the bitmap source-over on top.
            let windowBackground = window.backgroundColor.usingColorSpace(.deviceRGB)
            let hasOpaqueBackground = (windowBackground?.alphaComponent ?? 0) > 0.99
            NSGraphicsContext.saveGraphicsState()
            if cornerRadius > 0 {
                NSBezierPath(roundedRect: destination, xRadius: cornerRadius, yRadius: cornerRadius).addClip()
            }
            if hasOpaqueBackground {
                windowBackground!.setFill()
                destination.fill()
            }
            rep.draw(in: destination, from: .zero, operation: .sourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
            NSGraphicsContext.restoreGraphicsState()
        }

        // Composite the mouse pointer on top, at its current location.
        drawMousePointer(canvasRect: canvasRect)

        return canvasRep.cgImage
    }

    /// Returns the corner radius to use when compositing the given window.
    /// The real corner radius isn't exposed by AppKit (it's drawn by the private
    /// window frame view), so we approximate per window type:
    ///  - windows filling an entire screen (e.g. the full-screen browser window)
    ///    are kept square;
    ///  - the SEB Dock window draws its own rounded background, so it's not clipped;
    ///  - NSAlert panels use a larger radius than standard windows;
    ///  - everything else gets the standard macOS window rounding.
    private func windowCornerRadius(for window: NSWindow) -> CGFloat {
        let standardRadius: CGFloat = 10
        let alertRadius: CGFloat = 16
        let frame = window.frame
        for screen in NSScreen.screens {
            if abs(frame.width - screen.frame.width) < 1 && abs(frame.height - screen.frame.height) < 1 {
                return 0
            }
        }
        let className = NSStringFromClass(type(of: window))
        if className == "SEBDockWindow" {
            return 0
        }
        if className.contains("Alert") {
            return alertRadius
        }
        return standardRadius
    }

    /// Draws the current system mouse pointer into the active graphics context,
    /// positioned by its hot spot. Coordinates are AppKit screen space (bottom-left
    /// origin); cursor images use a top-left origin, so the hot spot is flipped.
    /// Must be called on the main thread with an active NSGraphicsContext.
    private func drawMousePointer(canvasRect: CGRect) {
        let cursor = NSCursor.currentSystem ?? NSCursor.current
        let cursorImage = cursor.image
        let size = cursorImage.size
        guard size.width > 0, size.height > 0 else {
            return
        }
        let hotSpot = cursor.hotSpot
        let mouseLocation = NSEvent.mouseLocation
        let destination = NSRect(x: mouseLocation.x - hotSpot.x - canvasRect.origin.x,
                                 y: mouseLocation.y - (size.height - hotSpot.y) - canvasRect.origin.y,
                                 width: size.width,
                                 height: size.height)
        cursorImage.draw(in: destination)
    }
#endif

    public func takeScreenShot(scale: Double, quantization: ColorQuantization) -> Data? {
        //        let displayID = CGMainDisplayID()
        //        guard var imageRef = CGDisplayCreateImage(displayID) else {
        //            return nil
        //        }
        
#if os(macOS)
        guard var imageRef = CGWindowListCreateImage(CGRectInfinite, .optionAll, CGWindowID(), CGWindowImageOption()) else {
            return nil
        }
#elseif os(iOS)
        guard let layer = UIApplication.shared.keyWindow?.layer else {
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(layer.frame.size, true, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: context)
        guard var imageRef = context.makeImage() else {
            return nil
        }
#endif
        return processImage(&imageRef, scale: scale, quantization: quantization)
    }
    
    private func processImage(_ imageRef: inout CGImage, scale: Double, quantization: ColorQuantization) -> Data? {
        if quantization != .color24Bpp || quantization != .color16Bpp || quantization != .color8Bpp {
            if let greyscaleImage = imageRef.greyscale() {
                imageRef = greyscaleImage
            }
        } else {
            let rgb5 = (quantization == .color8Bpp || quantization == .color16Bpp)
            if let withoutAlpha = imageRef.colorImageReduceSize(rgb5: rgb5) {
                imageRef = withoutAlpha
            }
        }
        if scale != 1 {
            guard let scaledImage = imageRef.resize(scale: scale) else {
                return nil
            }
            imageRef = scaledImage
        }
        let pngData = imageRef.pngData()
        return pngData
    }
}

import CoreGraphics
import CoreImage
import ImageIO

extension CIImage {
    
    public func convertToCGImage() -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(self, from: self.extent) {
            return cgImage
        }
        return nil
    }
    
    public func data() -> Data? {
        convertToCGImage()?.pngData()
    }
}

extension CGImage {
    
    public func pngData() -> Data? {
        let cfdata: CFMutableData = CFDataCreateMutable(nil, 0)
        if let destination = CGImageDestinationCreateWithData(cfdata, kUTTypePNG as CFString, 1, nil) {
            CGImageDestinationAddImage(destination, self, nil)
            if CGImageDestinationFinalize(destination) {
                return cfdata as Data
            }
        }
        
        return nil
    }
}

extension CGImage {
    
    func resize(scale: Double) -> CGImage? {
        let width = Double(self.width)
        let height = Double(self.height)
        let size = CGSize(width: width * scale, height: height * scale)
        return resize(size: size)
    }
    
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)
        
        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel
        
        
        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return context.makeImage()
    }
    
    func greyscale() -> CGImage? {
        let imgRect = CGRect(x: 0, y: 0, width: width, height: height)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        guard let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue) else {
            return nil
        }
        context.draw(self, in: imgRect)
        let imageRef = context.makeImage()
        return imageRef
    }
    
    func colorImageReduceSize(rgb5: Bool) -> CGImage? {
        let imgRect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: (rgb5 ? 5 : self.bitsPerComponent), bytesPerRow: self.bytesPerRow, space: self.colorSpace!, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.draw(self, in: imgRect)
        let imageRef = context.makeImage()
        return imageRef
    }
}
