//
//  ViewController.swift
//  EmojiDetector
//
//  Created by Ryan Arana on 7/30/17.
//  Copyright © 2017 Ryan Arana. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var cameraView: UIView!
    private var captureSession: AVCaptureSession!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            assertionFailure("Failed to get default capture device.")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession.addInput(input)

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

