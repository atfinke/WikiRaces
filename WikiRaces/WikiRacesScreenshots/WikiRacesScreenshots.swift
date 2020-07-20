//
//  WikiRacesScreenshots.swift
//  WikiRacesScreenshots
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import XCTest

class WikiRacesScreenshots: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        
        setupSnapshot(app)
        app.launch()
    }
    
    func testExample() {
        let prefix = "2_DARK"
        sleep(2)
        XCUIDevice.shared.orientation = .landscapeLeft
        snapshot(prefix + "_1_menu")
        
        app.buttons["CREATE"].tap()
        sleep(1)
        snapshot(prefix + "_2_host")
        
        app.buttons["play.fill"].tap()
        sleep(6)
        snapshot(prefix + "_3_voting")
        
        sleep(12)
        snapshot(prefix + "_4_game")
    }
    
}
