//
//  MenuViewController+GameKit.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit
import os.log

extension MenuViewController: GKGameCenterControllerDelegate {

    // MARK: - Game Center -

    func setupGKAuthHandler() {
        func auth(result: GKHelper.AuthResult) {
            switch result {
            case .error(let error):
                os_log("%{public}s: error: %{public}s", log: .gameKit, type: .info, #function, error.localizedDescription)
            case .controller(let controller):
                os_log("%{public}s: controller", log: .gameKit, type: .info, #function)
                if presentedViewController == nil, self.menuView.state != .noInterface {
                    present(controller, animated: true, completion: nil)
                }
            case .isAuthenticated:
                os_log("%{public}s: isAuthenticated", log: .gameKit, type: .info, #function)
                let metrics = PlayerCloudKitStatsManager.shared
                metrics.log(value: GKLocalPlayer.local.alias, for: "GCAliases")
            }
        }

        GKHelper.shared.authHandler = auth
    }

    func setupInviteHandler() {
        GKHelper.shared.inviteHandler = { invite in
            DispatchQueue.main.async {
                self.joinRace(invite: invite)
            }
        }
    }

    // MARK: - GKGameCenterControllerDelegate -

    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        dismiss(animated: true) {
            self.menuView.animateMenuIn()
        }
    }

}
