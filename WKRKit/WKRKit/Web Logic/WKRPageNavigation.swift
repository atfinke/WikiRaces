//
//  WKRPageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WebKit

class WKRPageNavigation: NSObject, WKNavigationDelegate {

    // MARK: - Properties

    let pageURLBlocked: (() -> Void)
    let pageLoadingError: (() -> Void)
    let pageStartedLoading: (() -> Void)
    let pageLoaded: ((WKRPage) -> Void)

    // MARK: - Initialization

    init(pageURLBlocked: @escaping (() -> Void),
         pageLoadingError: @escaping (() -> Void),
         pageStartedLoading: @escaping (() -> Void),
         pageLoaded: @escaping ((WKRPage) -> Void)) {
        self.pageURLBlocked = pageURLBlocked
        self.pageLoadingError = pageLoadingError
        self.pageStartedLoading = pageStartedLoading
        self.pageLoaded = pageLoaded
    }

    // MARK: - Helpers

    private func allow(url: URL?) -> Bool {
        guard let urlString = url?.absoluteString else {
            return false
        }
        for bannedFragment in WKRKitConstants.bannedURLFragments {
            if urlString.contains(bannedFragment) {
                return false
            }
        }
        if urlString == "about:blank" {
            return true
        }
        return urlString.contains(WKRKitConstants.baseURLString)
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
            pageURLBlocked()
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
            pageStartedLoading()

            WKRPageFetcher.fetchSource(url: requestURL) { (source) in
                DispatchQueue.main.async {
                    if let source = source {
                        webView.loadHTMLString(source, baseURL: requestURL)
                    }
                }
            }

            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            pageLoaded(WKRPage(title: webView.title, url: url))
        } else {
            fatalError("webView didFinish with no url")
        }
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        pageLoadingError()
        webView.scrollView.refreshControl?.endRefreshing()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        pageLoadingError()
        webView.scrollView.refreshControl?.endRefreshing()
    }

}
