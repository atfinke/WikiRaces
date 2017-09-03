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
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // MARK: - Encoding Validation

    func testEncoding<T: Codable & Equatable>(for original: T) {
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

            XCTAssertEqual(original, decodedCodable.typeOf(T.self))
            XCTAssertNotEqual(data, Data())

        } catch {
            XCTFail(error.localizedDescription)
        }
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

    // MARK: - Object Creators

    func uniquePlayer(named name: String? = nil) -> WKRPlayer {
        let name = name ?? "Andrew"
        let uuid = arc4random().description
        let profile = WKRPlayerProfile(name: name, playerID: uuid)
        return WKRPlayer(profile: profile, isHost: false)
    }

    func uniqueProfile(named name: String? = nil) -> WKRPlayerProfile {
        let name = name ?? "Andrew"
        let uuid = arc4random().description
        return WKRPlayerProfile(name: name, playerID: uuid)
    }

    func applePage(withSuffix suffix: String? = nil) -> WKRPage {
        let title = "Title"
        var urlString = "https://www.apple.com/"
        if let suffix = suffix {
            urlString += suffix
        }
        let url = URL(string: urlString)!
        return WKRPage(title: title, url: url)
    }

}

