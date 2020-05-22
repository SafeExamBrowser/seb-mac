//
//  ProctoringImageAnalyzer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

import UIKit
import Vision

@objc public protocol ProctoringImageAnayzerDelegate {
    func proctoringEvent(_ proctoringEvent: RemoteProctoringEventType) -> Void
}

public class ProctoringImageAnalyzer: NSObject {
 
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?

    @objc public func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                    print("did detect \(results.count) face(s)")
                    if results.count != 1 {
                        self.delegate?.proctoringEvent(RemoteProctoringEventTypeError)
                    } else {
                        if #available(iOS 12, *) {
                            let faceRoll = results[0].roll
                            let faceYaw = results[0].yaw
                            print("first face roll angle \(String(describing: faceRoll)), yaw angle \(String(describing: faceYaw))")
                            if faceYaw != nil && abs(faceYaw! as! Double) > 0.2 {
                                self.delegate?.proctoringEvent(RemoteProctoringEventTypeWarning)
                                return
                            }
                        }
                    }
                    self.delegate?.proctoringEvent(RemoteProctoringEventTypeNormal)
                } else {
                    print("did not detect any face")
                    self.delegate?.proctoringEvent(RemoteProctoringEventTypeError)
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
}
