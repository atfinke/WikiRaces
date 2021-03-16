//
//  MenuViewController+GameKit.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Game Center -

    func setupGKAuthHandler() {
        func auth(result: GKHelper.AuthResult) {
            switch result {
            case .error(let error):
                let info = "attemptGlobalAuthentication: " + error.localizedDescription
                PlayerFirebaseAnalytics.log(event: .error(info))
            case .controller(let controller):
                if presentedViewController == nil, self.menuView.state != .noInterface {
                    present(controller, animated: true, completion: nil)
                }
            case .isAuthenticated:
                let metrics = PlayerCloudKitStatsManager.shared
                metrics.log(value: GKLocalPlayer.local.alias, for: "GCAliases")
            }
        }

        GKHelper.shared.authHandler = auth
    }

    func setupInviteHandler() {
        GKHelper.shared.inviteHandler = { code in
            if code == "_GKINVITE" {
                self.joinRace(raceCode: code)
            } else {
                self.joinRace(raceCode: nil)
            }
        }
    }

    // MARK: - GKGameCenterControllerDelegate -

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        PlayerFirebaseAnalytics.log(event: .userAction(#function))
        dismiss(animated: true) {
            self.menuView.animateMenuIn()
        }
    }

}
