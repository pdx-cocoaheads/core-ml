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

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var resultsLabel: UILabel!
    private let processingQueue: DispatchQueue = DispatchQueue(label: "videoProcessingQueue")

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = nil
        textView.delegate = self
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        
    }
}
