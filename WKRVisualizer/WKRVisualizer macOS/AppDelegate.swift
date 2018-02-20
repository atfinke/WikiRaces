//
//  AppDelegate.swift
//  WKRVisualizer macOS
//
//  Created by Andrew Finke on 2/19/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        let url = URL(fileURLWithPath: "/Users/andrewfinke/Desktop/WKRRaceState")
        let results = WKRResultsGetter.fetchResults(atDirectory: url)
        print(results)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }


}

