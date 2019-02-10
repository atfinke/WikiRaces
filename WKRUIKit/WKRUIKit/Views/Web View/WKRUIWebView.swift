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

    public var text: String? {
        set {
            timeLabel.text = newValue
        }
        get {
            return timeLabel.text
        }
    }

    private let timeLabel = UILabel()
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
        backgroundColor = UIColor.wkrBackgroundColor
        translatesAutoresizingMaskIntoConstraints = false

        allowsLinkPreview = false
        allowsBackForwardNavigationGestures = false

        let features: [[UIFontDescriptor.FeatureKey: Int]] = [
            [
                .featureIdentifier: kNumberSpacingType,
                .typeIdentifier: kMonospacedNumbersSelector
            ]
        ]
        let fontDescriptor = UIFont.boldSystemFont(ofSize: 100.0).fontDescriptor.addingAttributes(
            [UIFontDescriptor.AttributeName.featureSettings: features]
        )

        timeLabel.text = "0"
        timeLabel.textColor = UIColor.white
        timeLabel.textAlignment = .center

        timeLabel.alpha = 0.0
        timeLabel.numberOfLines = 0

        timeLabel.adjustsFontSizeToFitWidth = true
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont(descriptor: fontDescriptor, size: 100.0)
        timeLabel.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2954569777)

        addSubview(timeLabel)

        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal

        let constraints = [
            timeLabel.topAnchor.constraint(equalTo: topAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            timeLabel.leftAnchor.constraint(equalTo: leftAnchor),
            timeLabel.rightAnchor.constraint(equalTo: rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: UIResponder.keyboardWillShowNotification,
                                               object: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        removeObserver(self, forKeyPath: "estimatedProgress")
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - State Updates

    @objc
    func keyboardWillShow() {
        resignFirstResponder()
        endEditing(true)
    }

    public func startedPageLoad() {
        progressView?.show()

        isUserInteractionEnabled = false

        let duration = WKRUIKitConstants.webViewAnimateOutDuration
        UIView.animate(withDuration: duration) {
            self.timeLabel.alpha = 1.0
        }
    }

    public func completedPageLoad() {
        progressView?.hide()

        isUserInteractionEnabled = true
        let duration = WKRUIKitConstants.webViewAnimateInDuration

        UIView.animate(withDuration: duration, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.timeLabel.alpha = 0.0
        }, completion: nil)
    }

    // MARK: - Web View Configuration

    private static func raceConfig() -> WKWebViewConfiguration? {
        let config = WKWebViewConfiguration()
        config.selectionGranularity = .character
        config.suppressesIncrementalRendering = false
        config.allowsAirPlayForMediaPlayback = false
        config.allowsPictureInPictureMediaPlayback = false
        config.dataDetectorTypes = []
        config.allowsInlineMediaPlayback = false
        config.mediaTypesRequiringUserActionForPlayback = .all

        let userContentController = WKUserContentController()

        WKContentRuleListStore.default()?
            .compileContentRuleList(forIdentifier: "WKRContentBlocker",
                                    encodedContentRuleList: WKRUIKitConstants.current.contentBlocker(),
                                    completionHandler: { (list, _) in
                                        guard let list = list else { return }
                                        userContentController.add(list)

            }
        )

        let startStyleScript = WKUserScript(source: WKRUIKitConstants.current.styleScript(),
                                            injectionTime: .atDocumentStart)
        let endStyleScript = WKUserScript(source: WKRUIKitConstants.current.styleScript(),
                                            injectionTime: .atDocumentEnd)
        let cleanScript = WKUserScript(source: WKRUIKitConstants.current.cleanScript(),
                                          injectionTime: .atDocumentEnd)

        userContentController.addUserScript(startStyleScript)
        userContentController.addUserScript(endStyleScript)
        userContentController.addUserScript(cleanScript)

        if WKRUIStyle.isDark {
            let startStyleScriptDark = WKUserScript(source: WKRUIKitConstants.current.styleScriptDark(),
                                                injectionTime: .atDocumentStart)
            let endStyleScriptDark = WKUserScript(source: WKRUIKitConstants.current.styleScriptDark(),
                                              injectionTime: .atDocumentEnd)
            userContentController.addUserScript(startStyleScriptDark)
            userContentController.addUserScript(endStyleScriptDark)
        }

        config.userContentController = userContentController
        return config
    }

    // MARK: - Progress View

    public override func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {

        guard keyPath == "estimatedProgress", let progress = change?[.newKey] as? Double  else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        progressView?.setProgress(Float(progress), animated: true)
    }

}
