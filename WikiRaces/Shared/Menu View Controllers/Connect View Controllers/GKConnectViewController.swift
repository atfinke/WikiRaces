//
//  ConnectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import GameKit
import UIKit
import WKRKit
import WKRUIKit
import os.log

class GKConnectViewController: VisualEffectViewController {

    // MARK: - Types -

    struct StartMessage: Codable {
        let hostName: String
        let gameSettings: WKRGameSettings
    }

    struct MiniMessage: Codable {
        enum Info: String, Codable {
            case connected, cancelled
        }
        let info: Info
        let uuid: UUID
    }

    // MARK: - Interface Elements -

    final var match: GKMatch?
    final var isPlayerHost: Bool
    final var isShowingError = false

    // MARK: - Initalization -

    init(isPlayerHost: Bool) {
        self.isPlayerHost = isPlayerHost
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        WKRSeenFinalArticlesStore.resetRemotePlayersSeenFinalArticles()
    }

    // MARK: - Helpers -

    final func disconnectFromMatch() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        
        match?.delegate = nil
        if isPlayerHost {
            sendMiniMessage(info: .cancelled)
        }
        match?.disconnect()
        GKMatchmaker.shared().cancel()
    }

    final func showError(title: String, message: String) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, title)
        
        guard !isShowingError else { return }
        isShowingError = true

        disconnectFromMatch()

        GKNotificationBanner.show(withTitle: title, message: message, completionHandler: nil)
    }

    final func sendMiniMessage(info: GKConnectViewController.MiniMessage.Info) {
        os_log("%{public}s: %{public}s", log: .gameKit, type: .info, #function, "\(info)")
        let message = GKConnectViewController.MiniMessage(info: info, uuid: UUID())
        guard let data = try? JSONEncoder().encode(message) else {
            fatalError()
        }
        try? match?.sendData(toAllPlayers: data, with: .reliable)
    }

    // MARK: - Match States -

    /// Cancels the join/create a race action and sends player back to main menu
    @objc
    final func cancelMatch() {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        disconnectFromMatch()

        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.navigationController?.popToRootViewController(animated: false)
        })
    }

    final func transitionToGame(for networkConfig: WKRPeerNetworkConfig, settings: WKRGameSettings) {
        os_log("%{public}s", log: .gameKit, type: .info, #function)
        
        guard !isShowingError else { return }
        isShowingError = true

        let controller = GameViewController(network: networkConfig, settings: settings)
        let nav = WKRUINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        nav.isModalInPresentation = true
        present(nav, animated: true, completion: { [weak self] in
            self?.view.alpha = 0
        })
    }
}
