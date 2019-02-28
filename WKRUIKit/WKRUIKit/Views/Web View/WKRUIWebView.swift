//
//  WKRUIWebView.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

public class WKRUIWebView: WKWebView, WKScriptMessageHandler {

    // MARK: - Type

    // WKScriptMessageHandler leaks due to a retain cycle
    private class ScriptMessageDelegate: NSObject, WKScriptMessageHandler {

        // MARK: - Properties

        weak var delegate: WKScriptMessageHandler?

        // MARK: - Initalization

        init(delegate: WKScriptMessageHandler) {
            self.delegate = delegate
            super.init()
        }

        // MARK: - WKScriptMessageHandler

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            delegate?.userContentController(userContentController, didReceive: message)
        }
    }

    // MARK: - Properties

    public var text: String? {
        set {
            linkCountLabel.text = newValue
        }
        get {
            return linkCountLabel.text
        }
    }

    private let linkCountLabel = UILabel()
    private let loadingView = UIView()
    private let slowConnectionLabel = UILabel()
    private let reloadButton = UIButton()

    public var progressView: WKRUIProgressView? {
        didSet {
            progressView?.isHidden = true
        }
    }

    public var pointsScrolled: Int {
        return Int(CGFloat(pixelsScrolled) / UIScreen.main.scale)
    }
    private var pixelsScrolled = 0
    private var lastPixelOffset = 0

    // MARK: - Initialization

    public init() {
        guard let config = WKRUIWebView.raceConfig() else {
            fatalError("WKRWebView couldn't load raceConfig")
        }
        super.init(frame: .zero, configuration: config)

        let messageDelegate = ScriptMessageDelegate(delegate: self)
        config.userContentController.add(messageDelegate, name: "scrollY")

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

        loadingView.alpha = 0.0
        loadingView.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.2954569777)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(loadingView)

        linkCountLabel.text = "0"
        linkCountLabel.textColor = UIColor.white
        linkCountLabel.textAlignment = .center
        linkCountLabel.numberOfLines = 0

        linkCountLabel.adjustsFontSizeToFitWidth = true
        linkCountLabel.font = UIFont(descriptor: fontDescriptor, size: 100.0)
        linkCountLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(linkCountLabel)

        slowConnectionLabel.text = "IF YOU SEE THIS FOR > 10 SECONDS, PLEASE LMK."
        slowConnectionLabel.textColor = UIColor.white
        slowConnectionLabel.textAlignment = .center
        slowConnectionLabel.numberOfLines = 0

        slowConnectionLabel.adjustsFontSizeToFitWidth = true
        slowConnectionLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        slowConnectionLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingView.addSubview(slowConnectionLabel)

        scrollView.decelerationRate = UIScrollView.DecelerationRate.normal

        let constraints = [
            loadingView.topAnchor.constraint(equalTo: topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            loadingView.leftAnchor.constraint(equalTo: leftAnchor),
            loadingView.rightAnchor.constraint(equalTo: rightAnchor),

            linkCountLabel.topAnchor.constraint(equalTo: loadingView.topAnchor),
            linkCountLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor),
            linkCountLabel.leftAnchor.constraint(equalTo: loadingView.leftAnchor),
            linkCountLabel.rightAnchor.constraint(equalTo: loadingView.rightAnchor),

            slowConnectionLabel.bottomAnchor.constraint(equalTo: loadingView.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            slowConnectionLabel.leftAnchor.constraint(equalTo: loadingView.leftAnchor),
            slowConnectionLabel.rightAnchor.constraint(equalTo: loadingView.rightAnchor)
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
        configuration.userContentController.removeScriptMessageHandler(forName: "scrollY")
    }

    // MARK: - State Updates

    @objc
    func keyboardWillShow() {
        resignFirstResponder()
        endEditing(true)
    }

    public func startedPageLoad() {
        progressView?.show()

        lastPixelOffset = 0
        isUserInteractionEnabled = false

        let duration = WKRUIKitConstants.webViewAnimateOutDuration
        UIView.animate(withDuration: duration) {
            self.loadingView.alpha = 1.0
        }
    }

    public func completedPageLoad() {
        progressView?.hide()

        isUserInteractionEnabled = true
        let duration = WKRUIKitConstants.webViewAnimateInDuration

        UIView.animate(withDuration: duration, delay: 0.0, options: .beginFromCurrentState, animations: {
            self.loadingView.alpha = 0.0
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

    // MARK: - WKScriptMessageHandler

    public func userContentController(_ userContentController: WKUserContentController,
                                      didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? Int else { return }
        switch message.name {
        case "scrollY":
            pixelsScrolled += abs(messageBody - lastPixelOffset)
            lastPixelOffset = messageBody
        default: return
        }
    }

    // MARK: - Other

    public func resetPixelCount() {
        pixelsScrolled = 0
        lastPixelOffset = 0
    }

}
