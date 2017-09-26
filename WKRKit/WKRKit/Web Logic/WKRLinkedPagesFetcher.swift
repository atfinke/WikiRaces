//
//  WKRLinkedPagesFetcher.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import WebKit

class WKRLinkedPagesFetcher: NSObject, WKScriptMessageHandler {

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
        let linksScript = WKUserScript(source: WKRKitConstants.getLinksScript(), injectionTime: .atDocumentEnd)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(linksScript)
        userContentController.add(self, name: "linkedPage")
        userContentController.add(self, name: "nextPage")
        userContentController.add(self, name: "finishedPage")
        config.userContentController = userContentController

        webView = WKWebView(frame: .zero, configuration: config)
    }

    // MARK: - Helpers

    func foundLinkOn(_ page: WKRPage) -> Bool {
        return foundURLs.contains(page.url)
    }

    // MARK: - State

    func start(for page: WKRPage) {
        let path = page.url.lastPathComponent
        let query = "&namespace=0&limit=500&hidetrans=1"
        guard let url = URL(string: WKRKitConstants.current.whatLinksHereURLString + "/" + path + query) else { return }
        load(url: url)
    }

    func stop() {
        hintIndex = 0
        nextPageURL = nil
        webView?.stopLoading()
    }

    func getHintPage(completionHandler: @escaping ((_ page: WKRPage?) -> Void)) {
        guard hintIndex < foundURLs.count else { return }
        WKRPageFetcher.fetch(url: foundURLs[hintIndex], completionHandler: completionHandler)
        hintIndex += 1
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
