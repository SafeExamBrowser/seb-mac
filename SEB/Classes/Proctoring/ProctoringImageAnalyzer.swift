//
//  ProctoringImageAnalyzer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

import UIKit
import Vision

@objc public protocol ProctoringImageAnayzerDelegate {
    func proctoringEvent(_ proctoringEvent: RemoteProctoringEventType, message: String?) -> Void
}

public class ProctoringImageAnalyzer: NSObject {
 
    fileprivate var proctoringState = remoteProctoringButtonStateDefault
    
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?

    @objc public func detectFace(in image: CVPixelBuffer) {
        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
            DispatchQueue.main.async {
                if let results = request.results as? [VNFaceObservation], results.count > 0 {
//                    print("did detect \(results.count) face(s)")
                    if results.count != 1 {
                        self.updateProctoringState(RemoteProctoringEventTypeError, message: "Number of detected faces: \(results.count)")
                    } else {
                        if #available(iOS 12, *) {
//                            let faceRoll = results[0].roll
//                            print("first face roll angle \(String(describing: faceRoll)), yaw angle \(String(describing: faceYaw))")
                            guard let faceYaw = results.first?.yaw else {
                                return
                            }
                            let faceYawDegrees = self.degrees(radians: faceYaw as! Double)
                            if abs(faceYawDegrees) > 20 {
                                self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face has an angle of \(faceYawDegrees)")
                                return
                            }
                        }
                    }
                    self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "One face detected")
                } else {
//                    print("did not detect any face")
                    self.updateProctoringState(RemoteProctoringEventTypeError, message: "No candidate face detected!")
                }
            }
        })
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
        try? imageRequestHandler.perform([faceDetectionRequest])
    }
    
    func updateProctoringState(_ proctoringEventType: RemoteProctoringEventType, message: String?) -> Void {
        if proctoringState != proctoringEventType {
            proctoringState = proctoringEventType
            self.delegate?.proctoringEvent(proctoringEventType, message: message)
        }
    }
    
    func degrees(radians: Double) -> Int {
        return Int(radians * 180 / .pi)
    }
}
