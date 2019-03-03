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

#if !MULTIWINDOWDEBUG
import FirebasePerformance
#endif

class GameKitConnectViewController: ConnectViewController {

    // MARK: - Types

    struct StartMessage: Codable {
        let hostName: String
    }

    // MARK: - Properties

    var isPlayerHost = false
    var hostPlayerAlias: String?
    var match: GKMatch?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCoreInterface()

        onQuit = { [weak self] in
            self?.match?.delegate = nil
            self?.match?.disconnect()
        }

        #if !MULTIWINDOWDEBUG
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
                self.showError(title: "Slow Connection",
                               message: "A fast internet connection is required to play WikiRaces.")
            }
        }

        toggleCoreInterface(isHidden: false, duration: 0.5)
    }

}
