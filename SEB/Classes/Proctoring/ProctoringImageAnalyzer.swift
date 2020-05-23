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
                    if results.count != 1 {
                        self.updateProctoringState(RemoteProctoringEventTypeError, message: "Number of detected faces: \(results.count)")
                    } else {
                        guard let landmarks = results.first?.landmarks else {
                            return
                        }
                                    let leftPupil = landmarks.leftPupil?.normalizedPoints.first
                                    let rightPupil = landmarks.rightPupil?.normalizedPoints.first

                        //            print((faceBounds.origin.y - leftPupil!.y)/faceBounds.size.height)
                        let facePitch = 0.5 - ((leftPupil!.y + rightPupil!.y)/2)
                                    
                        let faceYawCalculated = (0.5 - ((rightPupil!.x - leftPupil!.x)/2+leftPupil!.x))

                        if #available(iOS 12, *) {
//                            let faceRoll = results[0].roll
                            guard let faceYaw = results.first?.yaw else {
                                return
                            }
                            print("first face yaw angle: \(String(describing: faceYaw)), calculated: \(String(describing: faceYawCalculated)), pitch: \(facePitch)")

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
