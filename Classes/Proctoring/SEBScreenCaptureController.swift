//
//  SEBScreenCaptureController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.05.24.
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
//  (c) 2010-2024 Daniel R. Schneider, ETH Zurich, IT Services,
//  based on the original idea of Safe Exam Browser
//  by Stefan Schneider, University of Giessen. All Rights Reserved.
//
//  Contributor(s): ______________________________________.
//

import Foundation
#if os(iOS)
import MobileCoreServices
#endif

public class ScreenCaptureController {
    
    public init() {
    }
    
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
