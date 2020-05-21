//
//  ProctoringImageAnalyzer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

import UIKit
import Vision

public class ProctoringImageAnalyzer: NSObject {
    
    @objc public func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    print("did detect \(results.count) face(s)")
                    if #available(iOS 12, *) {
                        let faceRoll = results[0].roll
                        let faceYaw = results[0].yaw
                        print("first face roll angle \(String(describing: faceRoll)), yaw angle \(String(describing: faceYaw))")
                    } else {
                    }
                } else {
                    print("did not detect any face")
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
}
