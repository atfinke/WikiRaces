//
//  WKRCodable.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

internal struct WKRCodable: Codable {

    // MARK: - Types

    private struct WKREnumCodable: Codable {

        private enum WKREnumType: String, Codable {
            case gameState = "WKRGameState"
            case playerState = "WKRPlayerState"
            case playerMessage = "WKRPlayerMessage"
            case fatalError = "WKRFatalError"
        }

        private let type: WKREnumType
        private let rawValue: Int

        init<T: RawRepresentable>(_ object: T) where T.RawValue == Int {
            let subjectType = Mirror(reflecting: object).subjectType
            guard let enumType = WKREnumType(rawValue: "\(subjectType)") else {
                fatalError("Object not a WKREnumType")
            }
            type = enumType
            rawValue = object.rawValue
        }

        func typeOf<T: RawRepresentable>(_ type: T.Type) -> T? where T.RawValue == Int {
            guard let potentialObject = T(rawValue: rawValue) else { return nil }
            let subjectType = Mirror(reflecting: potentialObject).subjectType
            guard let enumType = WKREnumType(rawValue: "\(subjectType)") else {
                fatalError("Object not a WKREnumType")
            }
            guard enumType == self.type else {
                return nil
            }
            return potentialObject
        }
    }

    // MARK: - Properties

    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()

    let key: WKRCodable.Key
    let data: Data

    enum Key: String, Codable {
        case raw, int, enumCodable
    }

    // MARK: - Init

    init<T: Codable>(_ object: T) {
        self.init(key: .raw, object: object)
    }

    init(int object: WKRInt) {
        self.init(key: .int, object: object)
    }

    init<T: RawRepresentable>(enum object: T) where T.RawValue == Int {
        self.init(key: .enumCodable, object: WKREnumCodable(object))
    }

    private init<T: Codable>(key: WKRCodable.Key, object: T) {
        self.key = key
        do {
            self.data = try JSONEncoder().encode(object)
        } catch {
            fatalError(key.rawValue + ": \(T.self)")
        }
    }

    func typeOf<T: Codable>(_ type: T.Type) -> T? {
        return try? WKRCodable.decoder.decode(type, from: data)
    }

    func typeOfEnum<T: RawRepresentable>(_ type: T.Type) -> T? where T.RawValue == Int {
        let enumCodable = try? WKRCodable.decoder.decode(WKREnumCodable.self, from: data)
        return enumCodable?.typeOf(type)
    }

}
