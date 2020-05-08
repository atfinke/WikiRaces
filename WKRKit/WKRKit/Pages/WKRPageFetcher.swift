//
//  WKRPageFetcher.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

/// Feteched Wikipedia pages
public struct WKRPageFetcher {

    // MARK: - Properties

    /// The standard URLSession
    static private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 7.5
        config.timeoutIntervalForResource = 7.5
        return URLSession(configuration: config)
    }()

    static private let noCacheSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 7.5
        config.timeoutIntervalForResource = 7.5
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    static private let queue = DispatchQueue(
        label: "com.andrewfinke.wikiraces.pagefetcher",
        qos: .utility)

    // MARK: - Helpers

    /// Returns the title from the raw HTML
    private static func title(from string: String) -> String? {
        guard let titleAttributeStart = string.range(of: "<title>"),
            let titleAttributeEnd = string.range(of: "</title>") else {
                return nil
        }
        let range = Range(uncheckedBounds: (titleAttributeStart.upperBound, titleAttributeEnd.lowerBound))
        return String(string[range])
    }

    // MARK: - Fetching

    /// Fetches Wikipedia page with path ("/Apple_Inc.")
    public static func fetch(path: String, useCache: Bool, completionHandler: @escaping ((_ page: WKRPage?, _ isRedirect: Bool) -> Void)) {
        guard let url = URL(string: WKRKitConstants.current.baseURLString + path) else {
            completionHandler(nil, false)
            return
        }
        fetch(url: url, useCache: useCache, completionHandler: completionHandler)
    }

    /// Fetches a random Wikipedia page
    static func fetchRandom(completionHandler: @escaping ((_ page: WKRPage?) -> Void)) {
        guard let url = URL(string: WKRKitConstants.current.randomURLString) else {
            completionHandler(nil)
            return
        }
        fetch(url: url, useCache: true) { page, _ in
            completionHandler(page)
        }
    }

    /// Fetches a Wikipedia page at a given url
    static func fetch(url: URL, useCache: Bool, completionHandler: @escaping ((_ page: WKRPage?, _ isRedirect: Bool) -> Void)) {
        let session: URLSession
        if useCache {
            session = WKRPageFetcher.session
        } else {
            session = WKRPageFetcher.noCacheSession
        }
        let task = session.dataTask(with: url) { (data, response, _) in
            if let data = data, let string = String(data: data, encoding: .utf8), let responseUrl = response?.url {
                let page = WKRPage(title: title(from: string), url: responseUrl)
                let isRedirect = string.contains("Redirected from")
                completionHandler(page, isRedirect)
            } else {
                completionHandler(nil, false)
            }
        }
        task.resume()
    }

    /// Fetches a Wikipedia page source.
    static func fetchSource(url: URL,
                            useCache: Bool,
                            progressHandler: @escaping (_ progress: Float) -> Void,
                            completionHandler: @escaping (_ source: String?, _ error: Error?) -> Void) {
        let session: URLSession
        if useCache {
            session = WKRPageFetcher.session
        } else {
            session = WKRPageFetcher.noCacheSession
        }

        queue.async {
            var observation: NSKeyValueObservation?
            let task = session.dataTask(with: url) { (data, _, error) in
                observation?.invalidate()
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    completionHandler(string, nil)
                } else {
                    completionHandler(nil, error)
                }
            }
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                print("asdasd \(progress)")
                progressHandler(Float(progress.fractionCompleted))
            }
            task.resume()
        }
    }

}
