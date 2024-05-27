//
//  SEBScreenCaptureController.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 27.05.24.
//

import Foundation

public class ScreenCaptureController {
    
    public func takeScreenShot(scale: Double) -> Data? {
//        let displayID = CGMainDisplayID()
//        guard var imageRef = CGDisplayCreateImage(displayID) else {
//            return nil
//        }
        guard var imageRef = CGWindowListCreateImage(CGRectInfinite, .optionAll, CGWindowID(), CGWindowImageOption()) else {
            return nil
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

extension NSImage {
    
//    func resize(to size:CGSize) -> NSImage? {
//        let cgImage = self.cgImage
//        let destWidth = Int(size.width)
//        let destHeight = Int(size.height)
//        let bitsPerComponent = 8
//        let bytesPerPixel = cgImage.bitsPerPixel / bitsPerComponent
//        let destBytesPerRow = destWidth * bytesPerPixel
//        let context = CGContext(data: nil, width: destWidth, height: destHeight, bitsPerComponent: bitsPerComponent, bytesPerRow: destBytesPerRow, space: cgImage.colorSpace!, bitmapInfo: cgImage.bitmapInfo.rawValue)!
//        context.interpolationQuality = .high
//        context.draw(cgImage, in: CGRect(origin: CGPoint.zero, size: size))
//        return context.makeImage().flatMap { NSImage(cgImage: $0) }
//    }
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
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }

}
