//
//  WKRAppDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

internal class WKRAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func configureConstants() {
        WKRKitConstants.updateConstants()
        WKRUIConstants.updateConstants()

        // Don't be that app that prompts people when they first open it
        UserDefaults.standard.set(false, forKey: "ShouldPromptForRating")
    }

    func configureAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.wkrTextColor
        UINavigationBar.appearance().barTintColor = UIColor.white

        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: #colorLiteral(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
        ]
        window?.backgroundColor = UIColor.white
    }

}
