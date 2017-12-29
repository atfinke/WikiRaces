//
//  AppDelegate.swift
//  WikiRaces (Multi-Window)
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

@UIApplicationMain
internal class AppDelegate: WKRAppDelegate {

    //swiftlint:disable:next line_length
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        configureAppearance()
        configureConstants()
        return true
    }

}
