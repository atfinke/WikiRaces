//
//  WKRLanguageHackery.swift
//  WKRKit
//
//  Created by Andrew Finke on 7/17/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import os.log

/// A terrible, terrible approach, but I don't want to spend much time on this. + code quality/arch doesn't matter to me that much anymore given I will no longer be working on this project in a few weeks
internal class WKRLanguageHackery {

    // MARK: - Types-

    private struct WikiDataResponse: Decodable {
        struct Entity: Decodable {
            struct SiteLink: Decodable {
                let url: String
            }
            let sitelinks: [String: SiteLink]
        }

        private let entities: [String: Entity]
        func path(for language: String) -> String? {
            let site = "\(language).wikipedia.org/wiki"
            let urlString = entities
                .values
                .map { $0.sitelinks.values }
                .flatMap { $0 }
                .map { $0.url }
                .first(where: { $0.contains(site) })

            guard let string = urlString else {
                return nil
            }

            let components = string.components(separatedBy: site)
            guard components.count == 2 else {
                return nil
            }

            return components[1]
        }
    }

    // MARK: - Properties

    static private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 2
        config.timeoutIntervalForResource = 2
        return URLSession(configuration: config)
    }()

    static let shared = WKRLanguageHackery()
    private var language = "en"
    
    var isEnglish: Bool {
        return language == "en"
    }

    // MARK: - Initalization -

    private init() {}

    // MARK: - Helpers -

    func configure(for settings: WKRGameSettings) {
        language = settings.language.code
    }

    var baseURLString: String {
        return WKRKitConstants.current.baseURLString.replacingOccurrences(of: "en", with: language)
    }

    var whatLinksHereURLString: String {
        return WKRKitConstants.current.whatLinksHereURLString.replacingOccurrences(of: "en", with: language)
    }

    var randomURLString: String {
        return WKRKitConstants.current.randomURLString.replacingOccurrences(of: "en", with: language)
    }

    var pageTitleStringToReplace: String {
        if language == "es" {
            return " - Wikipedia, la enciclopedia libre"
        } else if language == "fr" {
            return " — Wikipédia"
        } else if language == "de" {
            return " – Wikipedia"
        } else if language == "ru" {
            return " — Википедия"
        } else {
            return WKRKitConstants.current.pageTitleStringToReplace
        }
    }

    func adjustedPath(for path: String, completion: @escaping ((String?) -> Void)) {
        guard language != "en" else {
            completion(path)
            return
        }

        let adjustedPath = path.dropFirst()
        let urlString = "https://www.wikidata.org/w/api.php?action=wbgetentities&format=json&sites=enwiki&redirects=no&props=sitelinks%2Furls&titles=\(adjustedPath)"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        let task = WKRLanguageHackery.session.dataTask(with: url) { data, _, _ in
            if let data = data, let response = try? JSONDecoder().decode(WikiDataResponse.self, from: data) {
                let newPath = response.path(for: self.language)
                os_log("fetched adjusted path: %{public}s -> %{public}s", log: .articlesValidation, type: .info, path, newPath ?? "-")
                completion(newPath)
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

}
