//
//  WKRLinkedPagesFetcher.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

final internal class WKRLinkedPagesFetcher: NSObject, WKScriptMessageHandler {

    // MARK: - Types

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
            self.delegate?.userContentController(userContentController, didReceive: message)
        }
    }

    // MARK: - Properties

    private let pageFetcher = WKRPageFetcher()

    private var hintIndex = 0
    private var nextPageURL: URL?
    private var viewPageURLs = [URL]()
    internal var foundURLs = [URL]()

    private var webView: WKWebView?

    // MARK: - Initialization

    override init() {
        super.init()

        let config = WKWebViewConfiguration()
        let linksScript = WKUserScript(source: WKRKitConstants.current.getLinksScript(), injectionTime: .atDocumentEnd)

        let messageDelegate = ScriptMessageDelegate(delegate: self)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(linksScript)
        userContentController.add(messageDelegate, name: "linkedPage")
        userContentController.add(messageDelegate, name: "nextPage")
        userContentController.add(messageDelegate, name: "finishedPage")
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
    }

    deinit {
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "linkedPage")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "nextPage")
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "finishedPage")
    }

    // MARK: - Helpers

    func foundLinkOn(_ page: WKRPage) -> Bool {
        return foundURLs.contains(page.url)
    }

    // MARK: - State

    func start(for page: WKRPage) {
        let query = "&namespace=0&limit=500&hidetrans=1"
        guard let url = URL(string: WKRKitConstants.current.whatLinksHereURLString + page.path + query) else { return }
        load(url: url)
    }

    func stop() {
        hintIndex = 0
        nextPageURL = nil
        webView?.stopLoading()
    }

    // MARK: - Message Actions

    private func found(linkedPage: String) {
        guard let url = URL(string: linkedPage) else { return }
        foundURLs.append(url)
    }

    private func load(url: URL?) {
        guard let webView = webView, let url = url else { return }
        nextPageURL = nil
        viewPageURLs.append(url)
        webView.load(URLRequest(url: url))
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let messageBody = message.body as? String else { return }
        switch message.name {
        case "linkedPage":
            found(linkedPage: messageBody)
        case "finishedPage":
            load(url: nextPageURL)
        case "nextPage":
            if let url = URL(string: messageBody), !viewPageURLs.contains(url) {
                nextPageURL = url
            }
        default:
            fatalError("unknown message \(message)")
        }
    }

}
