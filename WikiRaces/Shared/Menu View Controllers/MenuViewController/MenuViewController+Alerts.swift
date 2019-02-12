//
//  MenuViewController+Alerts.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/27/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

import WKRKit
import WKRUIKit

extension MenuViewController {

    func promptForCustomName(isHost: Bool) -> Bool {
        guard !UserDefaults.standard.bool(forKey: "PromptedCustomName") else {
            return false
        }
        UserDefaults.standard.set(true, forKey: "PromptedCustomName")

        let message = "Would you like to set a custom player name before racing?"
        let alertController = UIAlertController(title: "Set Name?", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForCustomNamePrompt:rejected"))
            PlayerMetrics.log(event: .namePromptResult, attributes: ["Result": "Cancelled"])
            if isHost {
                self.createRace()
            } else {
                self.joinRace()
            }
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForCustomNamePrompt:accepted"))
            PlayerMetrics.log(event: .namePromptResult, attributes: ["Result": "Accepted"])

            self.openSettings()
        })
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
        return true
    }

    func promptForInvalidName() {
        guard UserDefaults.standard.bool(forKey: "AttemptingMCPeerIDCreation") else {
            return
        }
        UserDefaults.standard.set(false, forKey: "AttemptingMCPeerIDCreation")

        //swiftlint:disable:next line_length
        let message = "There was an unexpected issue starting a race with your player name. This can often occur when your name has too many emojis or too many letters. Please set a new custom player name before racing."
        let alertController = UIAlertController(title: "Player Name Issue", message: message, preferredStyle: .alert)

        let laterAction = UIAlertAction(title: "Maybe Later", style: .cancel, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForInvalidName:rejected"))
        })
        alertController.addAction(laterAction)

        let settingsAction = UIAlertAction(title: "Change Name", style: .default, handler: { _ in
            PlayerMetrics.log(event: .userAction("promptForInvalidName:accepted"))
            self.openSettings()
        })
        alertController.addAction(settingsAction)

        present(alertController, animated: true, completion: nil)
    }

    /// Changes title label to build info
    @objc
    func showDebugPanel() {
        PlayerMetrics.log(event: .versionInfo)

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

        let mpcAction = UIAlertAction(title: "Use MPC", style: .default, handler: { _ in
            UserDefaults.standard.set(false, forKey: "NetworkTypeGameKit")
            #if DEBUG
            self.titleLabel.text = "WikiRaces [MPC]"
            #endif
        })
        alertController.addAction(mpcAction)

        let gkAction = UIAlertAction(title: "Use GameKit", style: .default, handler: { _ in
            UserDefaults.standard.set(true, forKey: "NetworkTypeGameKit")
            #if DEBUG
            self.titleLabel.text = "WikiRaces [GK]"
            #endif
        })
        alertController.addAction(gkAction)

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
