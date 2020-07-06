//
//  WKRKitRaceTests.swift
//  WKRKitTests
//
//  Created by Andrew Finke on 9/3/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest
@testable import WKRKit

class WKRKitRaceTests: WKRKitTestCase {

    func testPreRaceFetch() {
        let testExpectation = expectation(description: "finalPage")
        WKRPreRaceConfig.new(settings: WKRGameSettings()) { preRaceConfig, _  in
            XCTAssertNotNil(preRaceConfig)
            XCTAssert(preRaceConfig?.votingState.pages.count == WKRKitConstants.current.votingArticlesCount)

            if let config = preRaceConfig {
                self.testEncoding(for: config)
            }

            testExpectation.fulfill()
        }
        waitForExpectations(timeout: 6.0, handler: nil)
    }

}
