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
 
    fileprivate var faceDetectionDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.FaceDetection", qos: .background)

    fileprivate var detectingFace = false
    fileprivate var proctoringState = remoteProctoringButtonStateDefault
    
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?

    @objc public func detectFace(in image: CVPixelBuffer) {
        faceDetectionDispatchQueue.async {
            if !self.detectingFace {
                self.detectingFace = true
                        let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request: VNRequest, error: Error?) in
                            DispatchQueue.main.async {
                                if let results = request.results as? [VNFaceObservation], results.count > 0 {
                                    if results.count != 1 {
                                        self.updateProctoringState(RemoteProctoringEventTypeError, message: "Number of detected faces: \(results.count)")
                                    } else {
//                                        guard let landmarks = results.first?.landmarks else {
//                                            self.detectingFace = false
//                                            return
//                                        }
//                                        let leftPupil = landmarks.leftPupil?.normalizedPoints.first
//                                        let rightPupil = landmarks.rightPupil?.normalizedPoints.first
//
//                                        //            print((faceBounds.origin.y - leftPupil!.y)/faceBounds.size.height)
//                                        if leftPupil != nil && rightPupil != nil {
//                                            let facePitch = (leftPupil!.y + rightPupil!.y)/2
//                                            print(leftPupil!.y, rightPupil!.y, facePitch)
//                                            if facePitch < 0.5 {
//                                                self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face has a too high Pitch angle (\(leftPupil!.y))")
//                                                self.detectingFace = false
//                                                return
//                                            }
//                                        }
                                        
                                        //                        let faceYawCalculated = (0.5 - ((rightPupil!.x - leftPupil!.x)/2+leftPupil!.x))
                                        
                                        if #available(iOS 12, *) {
                                            //                            let faceRoll = results[0].roll
                                            guard let faceYaw = results.first?.yaw else {
                                                self.detectingFace = false
                                                return
                                            }
                                            //                            print("first face yaw angle: \(String(describing: faceYaw)), pitch: \(facePitch)")
                                            
                                            let faceYawDegrees = self.degrees(radians: faceYaw as! Double)
                                            if abs(faceYawDegrees) > 20 {
                                                self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face has an angle of \(faceYawDegrees)")
                                                self.detectingFace = false
                                                return
                                            }
                                        }
                                    }
                                    self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "One face detected")
                                } else {
                                    //                    print("did not detect any face")
                                    self.updateProctoringState(RemoteProctoringEventTypeError, message: "No candidate face detected!")
                                }
                                self.detectingFace = false
                            }
                        })
                        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .leftMirrored, options: [:])
                        try? imageRequestHandler.perform([faceDetectionRequest])
                    } else {
                        print("Still detecting face, dropping current request")
                    }
        }
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
