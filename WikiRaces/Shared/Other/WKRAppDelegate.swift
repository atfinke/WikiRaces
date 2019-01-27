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
        WKRUIKitConstants.updateConstants()

        // Don't be that app that prompts people when they first open it
        UserDefaults.standard.set(false, forKey: "ShouldPromptForRating")
    }

    func configureAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.wkrTextColor

        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.wkrTextColor
        ]
        window?.backgroundColor = UIColor.wkrBackgroundColor

        if WKRUIStyle.isDark {
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = UIColor.white
        }
    }

}
