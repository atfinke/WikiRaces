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
        snapshot("1_portrait")
        XCUIApplication().buttons["GLOBAL RACE"].tap()
        sleep(5)
        snapshot("2_game")
    }

}
