//
//  GameKitMatchmakingViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit

import WKRKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

class GameKitConnectViewController: ConnectViewController {

    // MARK: - Properties -

    var isPlayerHost = false
    var hostPlayerAlias: String?
    var match: GKMatch?

    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
    var findTrace: Trace?
    #endif

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCoreInterface()

        onQuit = { [weak self] in
            self?.match?.delegate = nil
            self?.match?.disconnect()
        }

        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        let playerName = GKLocalPlayer.local.alias
        Crashlytics.sharedInstance().setUserName(playerName)
        Analytics.setUserProperty(playerName, forName: "playerName")
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard isFirstAppear else {
            return
        }
        isFirstAppear = false

        runConnectionTest { [weak self] success in
            guard let self = self else { return }
            if success {
                self.toggleCoreInterface(isHidden: true, duration: 0.25)
                self.findMatch()
            } else if !success {
                self.showConnectionSpeedError()
            }
        }

        toggleCoreInterface(isHidden: false, duration: 0.5)
    }

}
