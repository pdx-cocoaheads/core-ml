//
//  ViewController.swift
//  EmojiDetector
//
//  Created by Ryan Arana on 7/30/17.
//  Copyright © 2017 Ryan Arana. All rights reserved.
//

/// Much of the video capture configuration and capture code is borrowed and slightly modified with 💖 from
/// https://github.com/hollance/YOLO-CoreML-MPSNNGraph/blob/master/TinyYOLO-CoreML/TinyYOLO-CoreML/VideoCapture.swift


import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController {
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!

    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let processingQueue: DispatchQueue = DispatchQueue(label: "videoProcessingQueue")

    private var request: VNCoreMLRequest!
    private let yolo = YOLO()

//    private let labels = [
//        "aeroplane", "bicycle", "bird", "boat", "bottle", "bus", "car", "cat",
//        "chair", "cow", "diningtable", "dog", "horse", "motorbike", "person",
//        "pottedplant", "sheep", "sofa", "train", "tvmonitor"
//    ]
    private let labels = [
        "✈️", "🚲", "🦅", "🚢", "🍻", "🚌", "🏎", "😸",
        "⑁", "🐄", "🍽", "🐶", "🐴", "🛵", "😁",
        "☘️", "🐑", "🛋", "🚂", "📺"
    ]

    private var lastTimestamp = CMTime()

    override func viewDidLoad() {
        super.viewDidLoad()

        formatter.numberStyle = .percent

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            assertionFailure("Failed to get default capture device.")
            return
        }

        guard let model = try? VNCoreMLModel(for: yolo.model.model) else {
            assertionFailure("Failed to load YOLO Model.")
            return
        }
        request = VNCoreMLRequest(model: model, completionHandler: visionRequestCompleted)
        request.imageCropAndScaleOption = .scaleFill

        captureSession = AVCaptureSession()

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: processingQueue)
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)
            ]
            output.alwaysDiscardsLateVideoFrames = true
            captureSession.addOutput(output)

            // We want the buffers to be in portrait orientation otherwise they are
            // rotated by 90 degrees. Need to set this _after_ addOutput()!
            output.connection(with: .video)?.videoOrientation = .portrait

            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer.videoGravity = .resizeAspectFill
            videoPreviewLayer.frame = view.layer.bounds
            cameraView.layer.addSublayer(videoPreviewLayer)

            captureSession.startRunning()
        } catch {
            print(error)
        }
    }

    private let formatter = NumberFormatter()
    private func visionRequestCompleted(request: VNRequest?, error: Error?) {
        guard let observations = request?.results as? [VNCoreMLFeatureValueObservation],
            let features = observations.first?.featureValue.multiArrayValue else { return }

        let boundingBoxes = yolo.computeBoundingBoxes(features: features).sorted {
            CGFloat($0.score) * $0.rect.width * $0.rect.height > CGFloat($1.score) * $1.rect.width * $1.rect.height
        }
        let result: YOLO.Prediction?
        if let topScore = boundingBoxes.first(where: { $0.score > 0.33 }) {
            result = topScore
        } else {
            result = nil
        }
        DispatchQueue.main.async {
            // Update UI here.
            if let result = result {
                self.resultsLabel.text = "\(self.labels[result.classIndex])"
                self.scoreLabel.text = self.formatter.string(for: result.score)
            } else {
                self.resultsLabel.text = "⁉️"
                self.scoreLabel.text = nil
            }
        }
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(1, Int32(3)) {
            lastTimestamp = timestamp

            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
                try? handler.perform([request])
            }
        }
    }
}

