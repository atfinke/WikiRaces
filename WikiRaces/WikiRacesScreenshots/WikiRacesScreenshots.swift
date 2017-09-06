//
//  WikiRacesScreenshots.swift
//  WikiRacesScreenshots
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest

class WikiRacesScreenshots: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        super.tearDown()
    }

    func testExample() {
        sleep(5)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(2)
        snapshot("Land")
        XCUIDevice.shared.orientation = .portrait
        sleep(2)
        snapshot("Por")
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

}
