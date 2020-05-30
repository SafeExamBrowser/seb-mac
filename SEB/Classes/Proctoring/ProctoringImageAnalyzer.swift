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
    fileprivate var proctoringDetectFaceTilt: Bool
    fileprivate var proctoringDetectFaceYaw: Bool
    
    fileprivate var faceDetectionDispatchQueue = DispatchQueue(label: "org.safeexambrowser.SEB.FaceDetection", qos: .background)
    
    fileprivate var detectingFace = false
    fileprivate var proctoringState = remoteProctoringButtonStateDefault
    
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    fileprivate var trackedObjectDisappeared = false
    
    @objc weak public var delegate: ProctoringImageAnayzerDelegate?
    
    override init() {
        let preferences = UserDefaults.standard
        enabled = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringAIEnable")
        proctoringDetectFaceCount = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceCount")
        proctoringDetectFaceTilt = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceTilt")
        proctoringDetectFaceYaw = preferences.secureBool(forKey: "org_safeexambrowser_SEB_proctoringDetectFaceYaw")
        
        super.init()

        self.prepareVisionRequest()
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

//            DispatchQueue.main.async {
//            }
        })
        
        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
    }
        
    @objc public func detectFace(in sampleBuffer: CMSampleBuffer) {
        faceDetectionDispatchQueue.async {
            if !self.detectingFace {
                self.detectingFace = true
            } else {
                print("Still detecting face, dropping current request")
            }
            
            var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
            
            let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
            if cameraIntrinsicData != nil {
                requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
            }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                print("Failed to obtain a CVPixelBuffer for the current output frame.")
                self.detectingFace = false
                return
            }
            
            let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
            
            guard let requests = self.trackingRequests, !requests.isEmpty else {
                // No tracking object detected, so perform initial detection
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                                orientation: exifOrientation,
                                                                options: requestHandlerOptions)
                
                do {
                    guard let detectRequests = self.detectionRequests else {
                        self.detectingFace = false
                        return
                    }
                    try imageRequestHandler.perform(detectRequests)
                } catch let error as NSError {
                    NSLog("Failed to perform FaceRectangleRequest: %@", error)
                }
                self.detectingFace = false
                return
            }
            
            do {
                try self.sequenceRequestHandler.perform(requests,
                                                        on: pixelBuffer,
                                                        orientation: exifOrientation)
            } catch let error as NSError {
                NSLog("Failed to perform SequenceRequest: %@", error)
            }
            
            // Setup the next round of tracking.
            var newTrackingRequests = [VNTrackObjectRequest]()
            for trackingRequest in requests {
                
                guard let results = trackingRequest.results else {
                    self.proctoringEventNoFace()
                    self.detectingFace = false
                    return
                }
                
                guard let observation = results[0] as? VNDetectedObjectObservation else {
                    self.proctoringEventNoFace()
                    self.detectingFace = false
                    return
                }
                
                if !trackingRequest.isLastFrame {
                    if observation.confidence > 0.3 {
                        trackingRequest.inputObservation = observation
                    } else {
                        trackingRequest.isLastFrame = true
                        self.trackedObjectDisappeared = true
                    }
                    print("Face UUID: \(observation.uuid) of \(results.count) faces.")
                    newTrackingRequests.append(trackingRequest)
                }
            }
            self.trackingRequests = newTrackingRequests
            
            if newTrackingRequests.isEmpty {
                // Nothing to track, so abort.
                if self.trackedObjectDisappeared {
                    self.trackedObjectDisappeared = false
                    self.proctoringEventFaceDisappeared()
                } else {
                    self.proctoringEventNoFace()
                }
                self.detectingFace = false
                return
            }
            
            // Perform face landmark tracking on detected faces.
            var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
            
            // Perform landmark detection on tracked faces.
            for trackingRequest in newTrackingRequests {
                
                let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
                    
                    if error != nil {
                        print("FaceLandmarks error: \(String(describing: error)).")
                    }
                    
                    guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                        let results = landmarksRequest.results as? [VNFaceObservation] else {
                            DispatchQueue.main.async {
                                self.processFaceObservations([])
                            }
                            return
                    }
                    
                    // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
                    DispatchQueue.main.async {
                        self.processFaceObservations(results)
                    }
                })
                
                
                guard let trackingResults = trackingRequest.results else {
                    self.detectingFace = false
                    return
                }
                
                guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                    self.detectingFace = false
                    return
                }
                let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
                faceLandmarksRequest.inputFaceObservations = [faceObservation]
                
                // Continue to track detected facial landmarks.
                faceLandmarkRequests.append(faceLandmarksRequest)
                
                let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                                orientation: exifOrientation,
                                                                options: requestHandlerOptions)
                
                do {
                    try imageRequestHandler.perform(faceLandmarkRequests)
                } catch let error as NSError {
                    NSLog("Failed to perform FaceLandmarkRequest: %@", error)
                }
                DispatchQueue.main.async {
                    self.processFaceObservations([faceObservation])
                }
            }
        }
    }
    
    func proctoringEventFaceDisappeared() -> Void {
        DispatchQueue.main.async {
            self.updateProctoringState(RemoteProctoringEventTypeError, message: "Candidate face disappeared!")
        }
    }
    
    func proctoringEventNoFace() -> Void {
        DispatchQueue.main.async {
            self.updateProctoringState(RemoteProctoringEventTypeError, message: "No face detected!")
        }
    }
    
    func processFaceObservations(_ faceObservations: [VNFaceObservation]) {
        if faceObservations.count > 0 {
            if faceObservations.count != 1 {
                self.updateProctoringState(RemoteProctoringEventTypeError, message: "Number of detected faces: \(faceObservations.count)")
            } else {
                guard let landmarks = faceObservations.first?.landmarks else {
                    self.detectingFace = false
                    return
                }
                let leftPupil = landmarks.leftPupil?.normalizedPoints.first
                let rightPupil = landmarks.rightPupil?.normalizedPoints.first
                
                //            print((faceBounds.origin.y - leftPupil!.y)/faceBounds.size.height)
                if leftPupil != nil && rightPupil != nil {
                    let facePitch = (leftPupil!.y + rightPupil!.y)/2
                    print(leftPupil!.y, rightPupil!.y, facePitch)
                    if facePitch < 0.7 {
                        self.updateProctoringState(RemoteProctoringEventTypeWarning, message: "Face has a too high Pitch angle (\(leftPupil!.y))")
                        self.detectingFace = false
                        return
                    }
                }
                
                let faceYawCalculated = (0.5 - ((rightPupil!.x - leftPupil!.x)/2+leftPupil!.x))
                print(faceYawCalculated)
                
                if #available(iOS 12, *) {
                    //                            let faceRoll = faceObservations[0].roll
                    guard let faceYaw = faceObservations.first?.yaw else {
                        self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "One face detected")
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
                } else {
                    self.updateProctoringState(RemoteProctoringEventTypeNormal, message: "One face detected")
                }
            }
        } else {
            //                    print("did not detect any face")
            self.updateProctoringState(RemoteProctoringEventTypeError, message: "No face detected!")
        }
        self.detectingFace = false
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
