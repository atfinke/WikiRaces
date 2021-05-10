//
//  AppDelegate.swift
//  WikiRaces (UI Catalog)
//
//  Created by Andrew Finke on 9/17/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

@UIApplicationMain
class AppDelegate: WKRAppDelegate {
    
//    var __window: WKRUIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureConstants()
        cleanTempDirectory()

//        __window = WKRUIWindow(frame: UIScreen.main.bounds)
//        let controller = ViewController()
//        let nav = WKRUINavigationController(rootViewController: controller)
//        nav.setNavigationBarHidden(true, animated: false)
//        __window?.rootViewController = nav
//        __window?.makeKeyAndVisible()

        return true
    }

}
