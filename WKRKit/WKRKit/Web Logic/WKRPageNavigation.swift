//
//  WKRPageNavigation.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WebKit

/// A WKNavigationDelegate for controlling Wikipedia page loads during the race
final internal class WKRPageNavigation: NSObject, WKNavigationDelegate {

    // MARK: - Types

    enum PageUpdate {
        /// Called when the user taps a banned link (i.e. an image)
        case urlBlocked(URL)
        /// Called when there is an issue loading the page
        case loadingError(Error?)
        /// Called when the page starts to load
        case startedLoading
        /// Called when the page has completed loading
        case loaded(WKRPage)

        /// Called when the page is being loaded
        case loadingProgess(Float)
    }

    // MARK: - Properties

    internal let pageUpdate: ((PageUpdate) -> Void)

    // MARK: - Initialization

    /// Creates a new WKRPageNavigation object
    init(pageUpdate: @escaping ((PageUpdate) -> Void)) {
        self.pageUpdate = pageUpdate
    }

    // MARK: - Helpers

    /// Determines the url is allowed (i.e. is a Wikipedia link, not an image, etc)
    ///
    /// - Parameter url: The url to check
    /// - Returns: If the page is legal for the race
    private func allow(url: URL?) -> Bool {
        guard let urlString = url?.absoluteString else {
            return false
        }
        if urlString == "about:blank" {
            return true
        }
        for bannedFragment in WKRKitConstants.current.bannedURLFragments {
            if urlString.contains(bannedFragment) {
                return false
            }
        }
        return urlString.contains(WKRKitConstants.current.baseURLString)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: (@escaping (WKNavigationActionPolicy) -> Void)) {

        // Not quite sure when request.url would be nil...
        guard let requestURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        // Make sure the url is legal for the race
        guard allow(url: requestURL) else {
            decisionHandler(.cancel)
            pageUpdate(.urlBlocked(requestURL))
            return
        }

        // If the url is for something on the same page, allow it, but don't add it to the history.
        guard requestURL.lastPathComponent != webView.url?.lastPathComponent else {
            // For pages with internal links, don't count the page twice and don't show loading
            decisionHandler(.allow)
            return
        }

        // True when using webView.loadHTMLString
        if navigationAction.navigationType == .other {
            decisionHandler(.allow)
        } else {
            pageUpdate(.startedLoading)

            WKRPageFetcher.fetchSource(url: requestURL,
                                       useCache: true,
                                       progressHandler: { progress in
                                        self.pageUpdate(.loadingProgess(progress))
                }, completionHandler: { source, error in
                DispatchQueue.main.async {
                    if let source = source {
                        webView.loadHTMLString(source, baseURL: requestURL)
                    } else {
                        self.pageUpdate(.loadingError(error))
                    }
                }
            })

            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            pageUpdate(.loaded(WKRPage(title: webView.title, url: url)))
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        pageUpdate(.loadingError(error))
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        pageUpdate(.loadingError(error))
    }

}
