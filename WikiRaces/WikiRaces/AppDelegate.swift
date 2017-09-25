//
//  AppDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import Crashlytics

@UIApplicationMain
class AppDelegate: WKRAppDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        guard let url = Bundle.main.url(forResource: "fabric.apikey", withExtension: nil),
            let key = try? String(contentsOf: url) else {
                fatalError()
        }
        Crashlytics.start(withAPIKey: key.replacingOccurrences(of: "\n", with: ""))

        StatsHelper.shared.start()
        configureConstants()
        configureAppearance()

        return true
    }

}
