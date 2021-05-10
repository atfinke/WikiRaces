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
#endif

@UIApplicationMain
final internal class AppDelegate: WKRAppDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        configureConstants()
        
        #if !targetEnvironment(macCatalyst)
        let isFirebaseDisabled = ProcessInfo.processInfo.environment["FIREBASE_DISABLED"]?.lowercased() == "true"
        if WKRKitConstants.current.isFirebaseEnabled && !isFirebaseDisabled {
            FirebaseApp.configure()
        }
        #endif

        DispatchQueue.global(qos: .utility).async {
            PlusStore.shared.sync()
            self.logCloudStatus()
            self.logBuild()
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.showBanHammer),
                                                   name: PlayerCloudKitStatsManager.banHammerNotification,
                                                   object: nil)
        }
        
        GKHelper.shared.start()
        
        PlayerStatsManager.shared.start()
        PlayerCloudKitStatsManager.shared.connect()

        if Defaults.isFastlaneSnapshotInstance {
            UIView.setAnimationsEnabled(false)
        }

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

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.windows.first?.rootViewController?
                .present(controller, animated: true, completion: nil)
        }
        
        PlayerFirebaseAnalytics.log(event: .banHammer)
    }

}
