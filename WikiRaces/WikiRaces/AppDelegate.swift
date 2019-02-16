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

import Crashlytics
import FirebaseCore

@UIApplicationMain
internal class AppDelegate: WKRAppDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        guard let url = Bundle.main.url(forResource: "fabric.apikey", withExtension: nil),
            let key = try? String(contentsOf: url).replacingOccurrences(of: "\n", with: "") else {
                fatalError("Failed to get API keys")
        }

        Crashlytics.start(withAPIKey: key)

        FirebaseApp.configure()

        StatsHelper.shared.start()
        configureConstants()
        configureAppearance()

        PlayerDatabaseMetrics.shared.connect()

        logCloudStatus()
        logInterfaceMode()
        logBuild()

        cleanTempDirectory()
        return true
    }

    // MARK: - Logging

    private func logCloudStatus() {
        CKContainer.default().accountStatus { (status, _) in
            PlayerMetrics.log(event: .cloudStatus,
                                attributes: ["CloudStatus": status.rawValue.description])
        }
    }

    private func logInterfaceMode() {
        let mode = WKRUIStyle.isDark ? "Dark" : "Light"
        PlayerMetrics.log(event: .interfaceMode, attributes: ["Mode": mode])
    }

    private func logBuild() {
        let appInfo = Bundle.main.appInfo
        PlayerDatabaseMetrics.shared.log(event: .app(coreVersion: appInfo.version,
                                                     coreBuild: appInfo.build,
                                                     kitConstants: WKRKitConstants.current.version,
                                                     uiKitConstants: WKRUIKitConstants.current.version))
    }

}
