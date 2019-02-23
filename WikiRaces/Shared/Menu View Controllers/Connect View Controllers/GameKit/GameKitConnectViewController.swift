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

   // MARK: - Properties

    var isPlayerHost = false
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

        runConnectionTest { success in
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

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else {
            fatalError("Destination is not a UINavigationController")
        }

        guard let destination = navigationController.rootViewController as? GameViewController,
            let isPlayerHost = sender as? Bool,
            let match = match else {
                fatalError("Destination rootViewController is not a GameViewController")
        }
        destination.networkConfig = .gameKit(match: match, isHost: isPlayerHost)
    }

}
