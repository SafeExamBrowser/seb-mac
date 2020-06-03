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
    func proctoringEvent(_ proctoringEvent: RemoteProctoringEventType, message: String?, userFeedback: Bool) -> Void
}

public class ProctoringImageAnalyzer: NSObject {
    
    @objc public var enabled: Bool
    
    fileprivate var proctoringDetectFaceCount: Bool
    fileprivate var proctoringDetectFaceCountDisplay: Bool
    fileprivate var proctoringDetectFacePitch: Bool
    fileprivate var proctoringDetectFaceYaw: Bool
    fileprivate var proctoringDetectFaceAngleDisplay: Bool

    fileprivate var faceDetectionDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.FaceDetection", qos: .background)
    
    fileprivate var detectingFace = false
    fileprivate var proctoringState = RemoteProctoringEventTypeDefault
    fileprivate var previousProctoringState = RemoteProctoringEventTypeDefault

    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    fileprivate var trackedObjectDisappeared = false
    
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?
    
    override init() {
        let preferences = UserDefaults.standard
        enabled = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringAIEnable")
        proctoringDetectFaceCount = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceCount")
        proctoringDetectFaceCountDisplay = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceCountDisplay")
        proctoringDetectFacePitch = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFacePitch")
        proctoringDetectFaceYaw = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceYaw")
        proctoringDetectFaceAngleDisplay = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceAngleDisplay")
        proctoringState = remoteProctoringButtonStateDefault

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
                self.updateProctoringStateTriggered(RemoteProctoringEventTypeError, message: "Number of detected faces: \(results.count)", userFeedback: proctoringDetectFaceCountDisplay)
                self.detectingFace = false
                return
            } else {
                
                if let landmarks = results.first?.landmarks {
                    let innerLipsPoints = landmarks.innerLips?.normalizedPoints

                    if proctoringDetectFacePitch && innerLipsPoints != nil {
                        var faceAngleMessage : String? = nil
                        // Inner lips
                        let innerLipsPoints = landmarks.innerLips?.normalizedPoints
                        if innerLipsPoints != nil {
                        }
                        let innerLipsBoundingBox = boundingBox(points: innerLipsPoints!)
                        let innerLipsUpper = innerLipsBoundingBox.origin.y + innerLipsBoundingBox.size.height
//                        print(innerLipsUpper)

                        if innerLipsUpper >= 0.39 {
                            faceAngleMessage = "Face turned upwards"
                        }
                        if innerLipsUpper < 0.31 {
                            faceAngleMessage = "Face turned downwards"
                        }
                        if faceAngleMessage != nil {
                            self.updateProctoringStateTriggered(RemoteProctoringEventTypeWarning, message: faceAngleMessage!, userFeedback: proctoringDetectFaceAngleDisplay)
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
                                self.updateProctoringStateTriggered(RemoteProctoringEventTypeWarning, message: "Face turned to the " + (faceYawDegrees > 0 ? "right" : "left"), userFeedback: proctoringDetectFaceAngleDisplay)
                                self.detectingFace = false
                                return
                            }
                        }
                    }
                }
            }
            if proctoringDetectFaceCount {
                self.updateProctoringStateTriggered(RemoteProctoringEventTypeNormal, message: "One properly front facing face detected", userFeedback: proctoringDetectFaceCountDisplay || proctoringDetectFaceAngleDisplay)
            } else {
                self.updateProctoringStateTriggered(RemoteProctoringEventTypeNormal, message: "", userFeedback: proctoringDetectFaceCountDisplay || proctoringDetectFaceAngleDisplay)
            }
        } else {
            if proctoringDetectFaceCount {
                self.updateProctoringStateTriggered(RemoteProctoringEventTypeError, message: "No candidate face detected!", userFeedback: proctoringDetectFaceCountDisplay)
            }
        }
        self.detectingFace = false
    }

    func updateProctoringStateTriggered(_ proctoringEventType: RemoteProctoringEventType, message: String?, userFeedback: Bool) -> Void {
        if proctoringEventType == previousProctoringState {
            updateProctoringState(proctoringEventType, message: message, userFeedback: userFeedback)
        } else {
            previousProctoringState = proctoringEventType
        }
    }
    
    func updateProctoringState(_ proctoringEventType: RemoteProctoringEventType, message: String?, userFeedback: Bool) -> Void {
        if proctoringState != proctoringEventType {
            proctoringState = proctoringEventType
            DispatchQueue.main.async {
                self.delegate?.proctoringEvent(proctoringEventType, message: message, userFeedback: userFeedback)
            }
        }
    }
    
    func boundingBox(points: [CGPoint]) -> CGRect {
        var xMin, xMax, yMin, yMax: CGFloat?
        for point in points {
            guard xMin != nil else {
                xMin = point.x
                xMax = xMin
                yMin = point.y
                yMax = yMin
                continue
            }
            if point.x < xMin! {
                xMin = point.x
            }
            if point.x > xMax! {
                xMax = point.x
            }
            if point.y < yMin! {
                yMin = point.y
            }
            if point.y > yMax! {
                yMax = point.y
            }
        }
        return CGRect(x: xMin!, y: yMin!, width: xMax! - xMin!, height: yMax! - yMin!)
    }
    
    func degrees(radians: Double) -> Int {
        return Int(radians * 180 / .pi)
    }
}
