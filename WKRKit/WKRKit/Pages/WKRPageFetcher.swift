//
//  WKRPageFetcher.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRPageFetcher {

    // MARK: - Properties

    static private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 5.0
        return URLSession(configuration: config)
    }()

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
    static func fetch(path: String, completionHandler: @escaping ((_ page: WKRPage?) -> Void)) {
        guard let url = URL(string: WKRRaceConstants.baseURLString + path) else {
            completionHandler(nil)
            return
        }
        fetch(url: url, completionHandler: completionHandler)
    }

    static func fetchRandom(completionHandler: @escaping ((_ page: WKRPage?) -> Void)) {
        guard let url = URL(string: WKRRaceConstants.randomURLString) else {
            completionHandler(nil)
            return
        }
        fetch(url: url, completionHandler: completionHandler)
    }

    static func fetch(url: URL, completionHandler: @escaping ((_ page: WKRPage?) -> Void)) {
        let task = WKRPageFetcher.session.dataTask(with: url) { (data, response, _) in
            if let data = data, let string = String(data: data, encoding: .utf8), let responseUrl = response?.url {
                completionHandler(WKRPage(title: title(from: string), url: responseUrl))
            } else {
                completionHandler(nil)
            }
        }
        task.resume()
    }

    static func fetchSource(url: URL, completionHandler: @escaping (_ source: String?) -> Void) {
        let task = WKRPageFetcher.session.dataTask(with: url) { (data, _, _) in
            if let data = data, let string = String(data: data, encoding: .utf8) {
                completionHandler(string)
            } else {
                completionHandler(nil)
            }
        }
        task.resume()
    }

}
