//
//  MenuViewController+Debug.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

import WKRKit
import WKRUIKit

extension MenuViewController {

    @objc
    func presentDebugController() {
        PlayerAnonymousMetrics.log(event: .versionInfo)

        let message = "If your name isn't Andrew, you probably shouldn’t be here."
        let alertController = UIAlertController(title: "Debug Panel",
                                                message: message,
                                                preferredStyle: .alert)

        let darkAction = UIAlertAction(title: "Toggle Dark UI", style: .default, handler: { _ in
            WKRUIStyle.isDark = !WKRUIStyle.isDark
            exit(1998)
        })
        alertController.addAction(darkAction)

        let buildAction = UIAlertAction(title: "Show Build Info", style: .default, handler: { _ in
            self.showDebugBuildInfo()
        })
        alertController.addAction(buildAction)

        let defaultsAction = UIAlertAction(title: "Show Defaults", style: .default, handler: { _ in
            self.showDebugDefaultsInfo()
        })
        alertController.addAction(defaultsAction)

        alertController.addCancelAction(title: "Dismiss")

        present(alertController, animated: true, completion: nil)
    }

    private func showDebugBuildInfo() {
        let versionKey = "CFBundleVersion"
        let shortVersionKey = "CFBundleShortVersionString"

        let appBundleInfo = Bundle.main.infoDictionary
        let kitBundleInfo = Bundle(for: WKRGameManager.self).infoDictionary
        let interfaceBundleInfo = Bundle(for: WKRUIStyle.self).infoDictionary

        guard let appBundleVersion = appBundleInfo?[versionKey] as? String,
            let appBundleShortVersion = appBundleInfo?[shortVersionKey] as? String,
            let kitBundleVersion = kitBundleInfo?[versionKey] as? String,
            let kitBundleShortVersion = kitBundleInfo?[shortVersionKey] as? String,
            let interfaceBundleVersion = interfaceBundleInfo?[versionKey] as? String,
            let interfaceBundleShortVersion = interfaceBundleInfo?[shortVersionKey] as? String else {
                fatalError("No bundle info dictionary")
        }

        let debugInfoController = DebugInfoTableViewController()
        debugInfoController.title = "Build Info"
        debugInfoController.info = [
            ("WikiRaces Version", "\(appBundleShortVersion) (\(appBundleVersion))"),
            ("WKRKit Version", "\(kitBundleShortVersion) (\(kitBundleVersion))"),
            ("WKRUIKit Version", "\(interfaceBundleShortVersion) (\(interfaceBundleVersion))"),

            ("WKRKit Constants Version", "\(WKRKitConstants.current.version)"),
            ("WKRUIKit Constants Version", "\(WKRUIKitConstants.current.version)")
        ]

        let navController = UINavigationController(rootViewController: debugInfoController)
        present(navController, animated: true, completion: nil)
    }

    private func showDebugDefaultsInfo() {
        let debugInfoController = DebugInfoTableViewController()
        debugInfoController.title = "User Defaults"
        debugInfoController.info = UserDefaults
            .standard
            .dictionaryRepresentation()
            .sorted { (lhs, rhs) -> Bool in
                return lhs.key.lowercased() < rhs.key.lowercased()
        }

        let navController = UINavigationController(rootViewController: debugInfoController)
        present(navController, animated: true, completion: nil)
    }
}
