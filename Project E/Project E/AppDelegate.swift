//
//  AppDelegate.swift
//  Project E
//
//  Created by Andrew Finke on 3/13/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: WKRUIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = WKRUIWindow(frame: UIScreen.main.bounds)
        let controller = UIViewController()
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()
        
        return true
    }


}

