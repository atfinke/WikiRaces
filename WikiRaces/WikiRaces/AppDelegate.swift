//
//  AppDelegate.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import UIKit

import WKRKit
import WKRUIKit

#if !targetEnvironment(macCatalyst)
import FirebaseCore
import Crashlytics
#endif

@UIApplicationMain
final internal class AppDelegate: WKRAppDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if !targetEnvironment(macCatalyst)
        FirebaseApp.configure()
        Crashlytics.start(withAPIKey: "80c3b2d37f1bca4e182e7fbf7976e6f069340b4d")
        #endif

        PlusStore.shared.sync()
        configureConstants()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showBanHammer),
                                               name: PlayerDatabaseMetrics.banHammerNotification,
                                               object: nil)

        PlayerStatsManager.shared.start()
        PlayerDatabaseMetrics.shared.connect()

        logCloudStatus()
        logBuild()

        cleanTempDirectory()

        if UserDefaults.standard.bool(forKey: "FASTLANE_SNAPSHOT") {
            UIView.setAnimationsEnabled(false)
        }

        window = WKRUIWindow(frame: UIScreen.main.bounds)
        let controller = MenuViewController()
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = nav
        window?.makeKeyAndVisible()

        return true
    }

    // MARK: - Logging -

    private func logCloudStatus() {
        CKContainer.default().accountStatus { (status, _) in
            PlayerAnonymousMetrics.log(event: .cloudStatus,
                                attributes: ["CloudStatus": status.rawValue.description])
        }
    }

    private func logBuild() {
        let appInfo = Bundle.main.appInfo
        let metrics = PlayerDatabaseMetrics.shared
        metrics.log(value: appInfo.version, for: "coreVersion")
        metrics.log(value: appInfo.build.description, for: "coreBuild")
        metrics.log(value: WKRKitConstants.current.version.description,
                    for: "WKRKitConstantsVersion")
        metrics.log(value: WKRUIKitConstants.current.version.description,
                    for: "WKRUIKitConstantsVersion")
        metrics.log(value: UIDevice.current.systemVersion,
                    for: "osVersion")
    }

    @objc
    func showBanHammer() {
        let controller = UIAlertController(title: "You have been banned from WikiRaces",
                                           message: nil,
                                           preferredStyle: .alert)

        window?.rootViewController?.present(controller,
                                            animated: true,
                                            completion: nil)

        PlayerAnonymousMetrics.log(event: .banHammer)
    }

}
