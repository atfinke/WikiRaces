//
//  AppDelegate.swift
//  WKRArticlesPreviewer
//
//  Created by Andrew Finke on 2/24/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

