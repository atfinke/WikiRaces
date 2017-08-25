//
//  WKRPageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WebKit

protocol WKRPageNavigationDelegate: class {
    func navigation(_ navigation: WKRPageNavigation, blockedURL url: URL)
    func navigation(_ navigation: WKRPageNavigation, startedLoading url: URL)
    func navigation(_ navigation: WKRPageNavigation, loadedPage page: WKRPage)
    func navigation(_ navigation: WKRPageNavigation, failedLoading error: Error)
}

class WKRPageNavigation: NSObject, WKNavigationDelegate {

    // MARK: - Properties

    weak var delegate: WKRPageNavigationDelegate?

    // MARK: - Helpers

    private func allow(url: URL?) -> Bool {
        guard let urlString = url?.absoluteString else {
            return false
        }
        for bannedFragment in WKRRaceConstants.bannedURLFragments {
            if urlString.contains(bannedFragment) {
                return false
            }
        }
        if urlString == "about:blank" {
            return true
        }
        return urlString.contains(WKRRaceConstants.baseURLString)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)) {

        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        guard allow(url: requestURL) else {
            decisionHandler(.cancel)
            delegate?.navigation(self, blockedURL: requestURL)
            return
        }

        guard requestURL.lastPathComponent != webView.url?.lastPathComponent else {
            // For pages with internal links, don't count the page twice and don't show loading
            decisionHandler(.allow)
            return
        }

        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
        } else {
            delegate?.navigation(self, startedLoading: requestURL)

            WKRPageFetcher.fetchSource(url: requestURL, completionHandler: { (source) in
                OperationQueue.main.addOperation {
                    if let source = source {
                        webView.loadHTMLString(source, baseURL: requestURL)
                    }
                }
            })

            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            delegate?.navigation(self, loadedPage: WKRPage(title: webView.title, url: url))
        } else {
            fatalError("webView didFinish with no url")
        }
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        delegate?.navigation(self, failedLoading: error)
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        delegate?.navigation(self, failedLoading: error)
        webView.scrollView.refreshControl?.endRefreshing()
    }

}
