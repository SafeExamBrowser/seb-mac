//
//  ProctoringImageAnalyzer.swift
//  SafeExamBrowser
//
//  Created by Daniel Schneider on 21.05.20.
//

import UIKit
import AVKit
import Vision

@objc public protocol ProctoringImageAnayzerDelegate {
    func proctoringEvent(_ proctoringEvent: RemoteProctoringEventType, message: String?) -> Void
}

public class ProctoringImageAnalyzer: NSObject {
    
    @objc public var enabled: Bool
    
    fileprivate var proctoringDetectFaceCount: Bool
    fileprivate var proctoringDetectFacePitch: Bool
    fileprivate var proctoringDetectFaceYaw: Bool

    fileprivate var faceDetectionDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.FaceDetection", qos: .background)
    
    fileprivate var detectingFace = false
    fileprivate var proctoringState = remoteProctoringButtonStateDefault
    fileprivate var previousProctoringState = remoteProctoringButtonStateDefault

    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    fileprivate var trackedObjectDisappeared = false
    
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?
    
    override init() {
        let preferences = UserDefaults.standard
        enabled = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringAIEnable")
        proctoringDetectFaceCount = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceCount")
        proctoringDetectFacePitch = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFacePitch")
        proctoringDetectFaceYaw = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceYaw")

        super.init()
    }
    
    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    
    fileprivate func prepareVisionRequest() {
        
        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    self.detectingFace = false
                    return
            }
            // Add the observations to the tracking list
            for observation in results {
                let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                faceTrackingRequest.trackingLevel = .fast
                if #available(iOS 12, *) {
                    faceTrackingRequest.revision = 2
                }
                requests.append(faceTrackingRequest)
            }
            self.trackingRequests = requests
            self.detectingFace = false
        })
        
        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
    }
    
    
    @objc public func detectFace(in sampleBuffer: CMSampleBuffer) {
        
            if !self.detectingFace {
                self.detectingFace = true
                
                faceDetectionDispatchQueue.async {
                    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                        print("Failed to obtain a CVPixelBuffer for the current output frame.")
                        self.detectingFace = false
                        return
                    }
                    let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
                    let faceDetectionRequest = VNDetectFaceLandmarksRequest(completionHandler: self.detectedFace(request:error:))

                    do {
                        try self.sequenceRequestHandler.perform(
                        [faceDetectionRequest],
                        on: pixelBuffer,
                        orientation: exifOrientation)
                    } catch {
                      print(error.localizedDescription)
                    }
                }
            } else {
                print("Still detecting face, dropping current request")
            }
    }
    
    func detectedFace(request: VNRequest, error: Error?) {
        if let results = request.results as? [VNFaceObservation], results.count > 0 {
            if proctoringDetectFaceCount && results.count != 1 {
                self.updateProctoringState(RemoteProctoringEventTypeError, message: "Number of detected faces: \(results.count)")
                self.detectingFace = false
                return
            } else {
                
                if let landmarks = results.first?.landmarks {
                    let leftPupil = landmarks.leftPupil?.normalizedPoints.first
                    let rightPupil = landmarks.rightPupil?.normalizedPoints.first
                    
                    let faceYawCalculated = (0.5 - ((rightPupil!.x - leftPupil!.x)/2+leftPupil!.x))
//                    if abs(faceYawCalculated) > 0.01 {
//                        self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face has a too high horizontal angle \(faceYawCalculated)")
//                        self.detectingFace = false
//                        return
//                    }
                    //            print((faceBounds.origin.y - leftPupil!.y)/faceBounds.size.height)
                    
                    if proctoringDetectFacePitch && leftPupil != nil && rightPupil != nil {
                        let facePitch = (leftPupil!.y + rightPupil!.y)/2
                        print(leftPupil!.y, rightPupil!.y, facePitch)
                        print("First face yaw angle: \(String(describing: faceYawCalculated)), pitch: \(facePitch)")
                        var faceAngleMessage : String? = nil
                        if facePitch >= 0.76 {
                            faceAngleMessage = "Face turned downwards"
                        }
                        if facePitch < 0.68 {
                            faceAngleMessage = "Face turned upwards"
                        }
                        if faceAngleMessage != nil {
                            self.updateProctoringStateTriggered(RemoteProctoringEventTypeWarning, message: faceAngleMessage!)
                            self.detectingFace = false
                            return
                        }
                    }
                }
                
                if #available(iOS 12, *) {
                    if proctoringDetectFaceYaw {
                        if let faceYaw = results.first?.yaw {
                            let faceYawDegrees = self.degrees(radians: faceYaw as! Double)
                            if abs(faceYawDegrees) > 20 {
                                self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face turned to the " + (faceYawDegrees > 0 ? "right" : "left"))
                                self.detectingFace = false
                                return
                            }
                        }
                    }
                }
            }
            if proctoringDetectFaceCount {
                self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "One face detected")
            } else {
                self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "")
            }
        } else {
            if proctoringDetectFaceCount {
                self.updateProctoringState(RemoteProctoringEventTypeError, message: "No candidate face detected!")
            }
        }
        self.detectingFace = false
    }

    func updateProctoringStateTriggered(_ proctoringEventType: RemoteProctoringEventType, message: String?) -> Void {
        if proctoringEventType == previousProctoringState {
            updateProctoringState(proctoringEventType, message: message)
        } else {
            previousProctoringState = proctoringEventType
        }
    }
    
    func updateProctoringState(_ proctoringEventType: RemoteProctoringEventType, message: String?) -> Void {
        if proctoringState != proctoringEventType {
            proctoringState = proctoringEventType
            DispatchQueue.main.async {
                self.delegate?.proctoringEvent(proctoringEventType, message: message)
            }
        }
    }
    
    func degrees(radians: Double) -> Int {
        return Int(radians * 180 / .pi)
    }
}
