//
//  RaceSettings+Codable.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import WKRKit

extension RaceSettings.StartPage: Codable {
    private enum CodingKeys: String, CodingKey {
        case base, page
    }

    private enum Base: String, Codable {
        case random, custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .random:
            try container.encode(Base.random, forKey: .base)
        case .custom(let page):
            try container.encode(Base.custom, forKey: .base)
            try container.encode(page, forKey: .page)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)

        switch base {
        case .random:
            self = .random
        case .custom:
            let page = try container.decode(WKRPage.self, forKey: .page)
            self = .custom(page)
        }
    }

}

extension RaceSettings.EndPage: Codable {
    private enum CodingKeys: String, CodingKey {
        case base, page
    }

    private enum Base: String, Codable {
        case curatedVoting, randomVoting, custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .curatedVoting:
            try container.encode(Base.curatedVoting, forKey: .base)
        case .randomVoting:
            try container.encode(Base.randomVoting, forKey: .base)
        case .custom(let page):
            try container.encode(Base.custom, forKey: .base)
            try container.encode(page, forKey: .page)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)

        switch base {
        case .curatedVoting:
            self = .curatedVoting
        case .randomVoting:
            self = .randomVoting
        case .custom:
            let page = try container.decode(WKRPage.self, forKey: .page)
            self = .custom(page)
        }
    }

}

extension RaceSettings.BannedPage: Codable {
    private enum CodingKeys: String, CodingKey {
        case base, page
    }

    private enum Base: String, Codable {
        case portal, custom
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .portal:
            try container.encode(Base.portal, forKey: .base)
        case .custom(let page):
            try container.encode(Base.custom, forKey: .base)
            try container.encode(page, forKey: .page)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(Base.self, forKey: .base)

        switch base {
        case .portal:
            self = .portal
        case .custom:
            let page = try container.decode(WKRPage.self, forKey: .page)
            self = .custom(page)
        }
    }

}
