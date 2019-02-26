//
//  WKRKitTestCase.swift
//  WKRKitTests
//
//  Created by Andrew Finke on 9/3/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WKRKit

class WKRKitTestCase: XCTestCase {

    override func setUp() {
        super.setUp()
        WKRKitConstants.updateConstants()
        let expectedVersion = 16
        XCTAssertEqual(WKRKitConstants.current.version,
                       expectedVersion,
                       "Installed WKRKitConstants not version \(expectedVersion)")
    }

    override func tearDown() {
        WKRKitConstants.removeConstants()
        super.tearDown()
    }

    // MARK: - Encoding Validation

    @discardableResult
    func testEncoding<T: Codable & Equatable>(for original: T) -> T {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        var data: Data
        var decodedObject: T

        do {
            data = try encoder.encode(original)
            decodedObject = try decoder.decode(T.self, from: data)

            XCTAssertEqual(original, decodedObject)
            XCTAssertNotEqual(data, Data())

            XCTAssertEqual(decodedObject, original)
        } catch {
            XCTFail(error.localizedDescription)
        }

        let codable = WKRCodable(original)
        do {
            data = try encoder.encode(codable)
            let decodedCodable = try decoder.decode(WKRCodable.self, from: data)

            XCTAssertEqual(codable.data, decodedCodable.data)

            guard let decodedType = decodedCodable.typeOf(T.self) else {
                XCTFail("Couldn't decode type \(T.self)")
                fatalError()
            }

            XCTAssertEqual(original, decodedType)
            XCTAssertNotEqual(data, Data())

            return decodedType
        } catch {
            XCTFail(error.localizedDescription)
        }

        fatalError("Should have returned decoded type")
    }

    func testEnumEncoding<T: Equatable & RawRepresentable>(for original: T) where T.RawValue == Int {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let codable = WKRCodable(enum: original)
        var data: Data

        do {
            data = try encoder.encode(codable)
            let decodedCodable = try decoder.decode(WKRCodable.self, from: data)

            XCTAssertEqual(codable.data, decodedCodable.data)

            XCTAssertEqual(original, decodedCodable.typeOfEnum(T.self))
            XCTAssertNotEqual(data, Data())

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

}

extension WKRPage {
    static func mockApple(withSuffix suffix: String? = nil) -> WKRPage {
        let title = "Apple"
        var urlString = "https://www.apple.com/"
        if let suffix = suffix {
            urlString += suffix
        }
        let url = URL(string: urlString)!
        return WKRPage(title: title, url: url)
    }
}

extension WKRPlayer {
    static func mock(named name: String? = nil) -> WKRPlayer {
        let profile = WKRPlayerProfile.mock(named: name)
        return WKRPlayer(profile: profile, isHost: false)
    }
}

extension WKRPlayerProfile {
    static func mock(named name: String? = nil) -> WKRPlayerProfile {
        let name = name ?? "Andrew"
        let uuid = arc4random().description
        return WKRPlayerProfile(name: name, playerID: uuid)
    }
}
