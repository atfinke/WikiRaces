//
//  WKRAppDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/25/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import StoreKit

import WKRKit
import WKRUIKit

internal class WKRAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func configureConstants() {
        WKRKitConstants.updateConstants()
        WKRUIKitConstants.updateConstants()

        // Don't be that app that prompts people when they first open it
        SKStoreReviewController.shouldPromptForRating = false
    }

    func configureAppearance() {
        UINavigationBar.appearance().tintColor = UIColor.wkrTextColor

        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.wkrTextColor,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        window?.backgroundColor = UIColor.wkrBackgroundColor

        if WKRUIStyle.isDark {
            UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).textColor = UIColor.white
        }
    }

    func cleanTempDirectory() {
        let maxDayAge = 14.0
        let maxTimeInterval = maxDayAge * 60 * 60
        let manager = FileManager.default
        do {
            let path = NSTemporaryDirectory()
            let contents = try manager.contentsOfDirectory(atPath: path)
            for file in contents {
                let filePath = path + file
                let attributes = try manager.attributesOfItem(atPath: filePath)
                if let date = attributes[FileAttributeKey.creationDate] as? Date,
                    -date.timeIntervalSinceNow > maxTimeInterval {
                    try manager.removeItem(atPath: filePath)
                }
            }
        } catch {
            print(error)
        }
    }

}
