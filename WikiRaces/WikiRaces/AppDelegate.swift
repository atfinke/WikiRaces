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
import FirebaseCrashlytics
#endif

@UIApplicationMain
final internal class AppDelegate: WKRAppDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        #if !targetEnvironment(macCatalyst)
        FirebaseApp.configure()
        #endif

        GKHelper.shared.start()
        PlusStore.shared.sync()
        configureConstants()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(showBanHammer),
                                               name: PlayerCloudKitStatsManager.banHammerNotification,
                                               object: nil)

        PlayerStatsManager.shared.start()
        PlayerCloudKitStatsManager.shared.connect()

        logCloudStatus()
        logBuild()

        cleanTempDirectory()

        if Defaults.isFastlaneSnapshotInstance {
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
            PlayerFirebaseAnalytics.log(event: .cloudStatus,
                                attributes: ["CloudStatus": status.rawValue.description])
        }
    }

    private func logBuild() {
        let appInfo = Bundle.main.appInfo
        let metrics = PlayerCloudKitStatsManager.shared
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

        PlayerFirebaseAnalytics.log(event: .banHammer)
    }

}
