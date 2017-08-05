//
//  WKRUIWebView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

public class WKRUIWebView: WKWebView {

    // MARK: - Properties

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()

    private let timeLabel = UILabel()

    private var refreshControl: UIRefreshControl? {
        return scrollView.refreshControl
    }

    public var progressView: WKRUIProgressView? {
        didSet {
            progressView?.isHidden = true
        }
    }

    // MARK: - Initialization

    public init() {
        guard let config = WKRUIWebView.raceConfig() else {
            fatalError("WKRWebView couldn't load raceConfig")
        }
        super.init(frame: .zero, configuration: config)

        isOpaque = false
        backgroundColor = UIColor.clear
        translatesAutoresizingMaskIntoConstraints = false

        allowsLinkPreview = false
        allowsBackForwardNavigationGestures = false

        timeLabel.text = "0"
        timeLabel.textColor = UIColor.white
        timeLabel.textAlignment = .center
        timeLabel.adjustsFontSizeToFitWidth = true

        let features: [[UIFontDescriptor.FeatureKey: Int]] = [[
            .featureIdentifier: kNumberSpacingType,
            .typeIdentifier: kMonospacedNumbersSelector
            ]]
        let fontDescriptor = UIFont.boldSystemFont(ofSize: 100.0).fontDescriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.featureSettings: features]
        )

        timeLabel.font = UIFont(descriptor: fontDescriptor, size: 100.0)
        timeLabel.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        timeLabel.alpha = 0.0
        timeLabel.numberOfLines = 0
        addSubview(timeLabel)

        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        scrollView.decelerationRate = UIScrollViewDecelerationRateNormal

        let constraints = [
            timeLabel.topAnchor.constraint(equalTo: topAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            timeLabel.leftAnchor.constraint(equalTo: leftAnchor),
            timeLabel.rightAnchor.constraint(equalTo: rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reload), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: .UIKeyboardWillShow,
                                               object: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - State Updates

    @objc func keyboardWillShow() {
        resignFirstResponder()
        endEditing(true)
    }

    public func startedPageLoad() {
        progressView?.show()

        isUserInteractionEnabled = false

        let duration = WKRUIConstants.webViewAnimateOutDuration
        UIView.animate(withDuration: duration, animations: {
            self.timeLabel.alpha = 1.0
        })
    }

    public func completedPageLoad() {
        progressView?.hide()

        let duration = WKRUIConstants.webViewAnimateInDuration

        UIView.animate(withDuration: duration, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.timeLabel.alpha = 0.0
        }, completion: { _ in
            self.isUserInteractionEnabled = true
        })
    }

    // MARK: - Web View Configuration

    private static func raceConfig() -> WKWebViewConfiguration? {
        let config = WKWebViewConfiguration()
        config.selectionGranularity = .character
        config.suppressesIncrementalRendering = true
        config.allowsAirPlayForMediaPlayback = false
        config.allowsPictureInPictureMediaPlayback = false

        guard let preHideScript = script(named: "WKRPreHideScript", injectionTime: .atDocumentStart),
            let postHideScript = script(named: "WKRPostHideScript", injectionTime: .atDocumentEnd) else {
                return nil
        }

        let userContentController = WKUserContentController()
        userContentController.addUserScript(preHideScript)
        userContentController.addUserScript(postHideScript)
        config.userContentController = userContentController
        return config
    }

    private static func script(named name: String, injectionTime: WKUserScriptInjectionTime) -> WKUserScript? {
        guard let url = Bundle(for: self).url(forResource: name, withExtension: "js") else {
            return nil
        }
        guard let source = try? String(contentsOf: url) else {
            return nil
        }
        return WKUserScript(source: source, injectionTime: injectionTime, forMainFrameOnly: true)
    }

    // MARK: - Progress View

    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey : Any]?,
                                      context: UnsafeMutableRawPointer?) {

        guard keyPath == "estimatedProgress", let progress = change?[.newKey] as? Double  else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        progressView?.setProgress(Float(progress), animated: true)
    }

    deinit {
        removeObserver(self, forKeyPath: "estimatedProgress")
    }

}

