//
//  qrCodeGenerator.swift
//  SEB
//
//  Created by Daniel Schneider on 21.01.23.
//

import Foundation

@objc public class QRCodeGenerator: NSObject {

    @objc public class func generateQRCode(from string: String) -> CIImage? {
        let data = string.data(using: String.Encoding.ascii)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return output
            }
        }
        return nil
    }
}
