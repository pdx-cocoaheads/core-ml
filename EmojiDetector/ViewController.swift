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
import CoreML

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var labelBottomConstraint: NSLayoutConstraint!
    private let processingQueue: DispatchQueue = DispatchQueue(label: "videoProcessingQueue")

    private let model = SentimentPolarity()
    private let options: NSLinguisticTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther]
    private lazy var tagger = NSLinguisticTagger(
        tagSchemes: NSLinguisticTagger.availableTagSchemes(forLanguage: "en"),
        options: Int(self.options.rawValue)
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = nil
        textView.delegate = self
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(notification:)),
            name: .UIKeyboardDidShow,
            object: nil
        )

        textView.becomeFirstResponder()
        resultsLabel.text = "👋"
    }

    @objc private func keyboardDidShow(notification: Notification) {
        guard let keyboardRect = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue else { return }
        labelBottomConstraint.constant = -keyboardRect.size.height - 8
        view.layoutIfNeeded()
    }
}

extension ViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        guard let text = textView.text else {
            resultsLabel.text = "😑"
            return
        }

        guard text.count > 3 else {
            resultsLabel.text = "🤔"
            return
        }

        var input = [String: Double]()
        tagger.string = text
        let range = NSRange(location: 0, length: text.utf16.count)

        tagger.enumerateTags(in: range, scheme: .nameType, options: options) { _, tokenRange, _, _ in
            let token = (text as NSString).substring(with: tokenRange).lowercased()
            guard token.count >= 3 else { return }

            input[token] = input[token, default: 0] + 1
        }

        let output = try! model.prediction(input: input)
        switch output.classLabel {
        case "Pos":
            resultsLabel.text = positiveEmoji(for: output.classProbability[output.classLabel, default: 0])
        case "Neg":
            resultsLabel.text = negativeEmoji(for: output.classProbability[output.classLabel, default: 0])
        default:
            resultsLabel.text = output.classLabel
        }
    }

    private func positiveEmoji(for confidence: Double) -> String {
        switch confidence {
        case 0.25..<0.45: return "🙂"
        case 0.45..<0.55: return "😁"
        case 0.55...: return "😂"
        default: return "🤔"
        }
    }

    private func negativeEmoji(for confidence: Double) -> String {
        switch confidence {
        case 0.25..<0.45: return "😕"
        case 0.45..<0.55: return "☹️"
        case 0.55...: return "😡"
        default: return "🤔"
        }
    }
}
