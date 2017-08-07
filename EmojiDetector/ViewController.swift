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

class ViewController: UIViewController {
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    private let processingQueue: DispatchQueue = DispatchQueue(label: "videoProcessingQueue")

    private var lastTimestamp = CMTime()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            assertionFailure("Failed to get default capture device.")
            return
        }

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
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Because lowering the capture device's FPS looks ugly in the preview,
        // we capture at full speed but only call the delegate at its desired
        // framerate.
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let deltaTime = timestamp - lastTimestamp
        if deltaTime >= CMTimeMake(1, Int32(15)) {
            lastTimestamp = timestamp
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)

            // TODO: Analyze dat imageBuffer.
            let result = "⁉️"
            DispatchQueue.main.async {
                // Update UI here.
                self.resultsLabel.text = result
            }
        }
    }
}

