//
//  MPCConnectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import GameKit
import MultipeerConnectivity
import UIKit

import WKRKit
import WKRUIKit

#if !MULTIWINDOWDEBUG
import FirebasePerformance
#endif

internal class MPCConnectViewController: ConnectViewController {

    // MARK: - Interface Elements

    let inviteView = UIView()
    let hostNameLabel = UILabel()
    let acceptButton = UIButton()
    let declineButton = UIButton()

    // MARK: - Properties

    var playerName = UIDevice.current.name
    var isValidPlayerName = false
    var isSolo = false
    var isPlayerHost = false
    var isShowingInvite = false

    // MARK: - MPC Properties

    var advertiser: MCNearbyServiceAdvertiser?
    var activeInvite: ((Bool, MCSession) -> Void)?
    var activeInviteTimeoutTimer: Timer?

    var invites = [(handler: ((Bool, MCSession) -> Void)?, host: MCPeerID, context: MPCHostContext?)]()

    var peerID: MCPeerID!
    var hostPeerID: MCPeerID?
    var hostContext: MPCHostContext?

    let serviceType = "WKRPeer30"
    lazy var session: MCSession = {
        return MCSession(peer: self.peerID)
    }()

    #if !MULTIWINDOWDEBUG
    var connectingTrace: Trace?
    #endif

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Gets either the player name specified in settings.app, then GK alias, the device name
        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            playerName = name
            PlayerAnonymousMetrics.log(event: .nameType, attributes: ["Type": "CustomName"])
        } else if GKLocalPlayer.local.isAuthenticated {
            playerName = GKLocalPlayer.local.alias
            PlayerAnonymousMetrics.log(event: .nameType, attributes: ["Type": "GCAlias"])
        } else {
            PlayerAnonymousMetrics.log(event: .nameType, attributes: ["Type": "DeviceName"])
        }

        #if !MULTIWINDOWDEBUG
        Crashlytics.sharedInstance().setUserName(playerName)
        Analytics.setUserProperty(playerName, forName: "playerName")
        #endif

        PlayerAnonymousMetrics.log(event: .userAction("Using player name \(playerName)"))
        isValidPlayerName = playerName.utf8.count > 0 && playerName.utf8.count < 40
        guard isValidPlayerName else { return }

        // Uses existing peer ID object if already created (recommended per Apple docs)
        if let pastPeerIDData = UserDefaults.standard.data(forKey: "PeerID"),
            let lastPeerID = NSKeyedUnarchiver.unarchiveObject(with: pastPeerIDData) as? MCPeerID,
            lastPeerID.displayName == playerName {
            peerID = lastPeerID
        } else {
            // Attempting to prevent https://github.com/atfinke/WikiRaces/issues/43
            // Also, see rdar://47570877
            UserDefaults.standard.set(true, forKey: "AttemptingMCPeerIDCreation")
            peerID = MCPeerID(displayName: playerName)
            UserDefaults.standard.set(false, forKey: "AttemptingMCPeerIDCreation")
            if let peerID = peerID {
                let data = NSKeyedArchiver.archivedData(withRootObject: peerID)
                UserDefaults.standard.set(data, forKey: "PeerID")
            }
        }

        setupCoreInterface()
        setupInviteInterface()

        onQuit = { [weak self] in
            self?.session.delegate = nil
            self?.session.disconnect()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAdvertising()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard isFirstAppear else {
            return
        }
        isFirstAppear = false

        // Test the connection to Wikipedia
        runConnectionTest { [weak self] success in
            guard let self = self else { return }
            if success && self.isValidPlayerName {
                if self.isPlayerHost {
                    self.toggleCoreInterface(isHidden: true,
                                        duration: 0.25,
                                        and: [self.inviteView],
                                        completion: {
                                            self.presentHostInterface()
                    })
                } else {
                    self.startAdvertising()
                }
            } else if !success {
                self.showConnectionSpeedError()
            }
        }

        toggleCoreInterface(isHidden: false, duration: 0.5)

        if !isValidPlayerName {
            let length = playerName.count == 0 ? "Short" : "Long"
            let message = "Your player name is too \(length.lowercased()). "
            showError(title: "Player Name Too \(length)",
                      message: message +  "Would you like to open settings to adjust it?",
                      showSettingsButton: true)
        }
    }

    // MARK: - State Changes

    func stopAdvertising() {
        advertiser?.stopAdvertisingPeer()

        // Reject all the pending invites
        for invite in invites {
            invite.handler?(false, session)
        }
    }

    func presentHostInterface() {
        let controller = MPCHostViewController(style: .grouped)
        controller.peerID = peerID
        controller.session = session
        controller.serviceType = serviceType
        controller.listenerUpdate = { [weak self] update in
            guard let self = self else { return }
            switch update {
            case .startMatch(let isSolo):
                self.isSolo = isSolo
                self.dismiss(animated: true, completion: {
                    var networkConfig: WKRPeerNetworkConfig = .solo(name: self.playerName)
                    if !isSolo {
                        networkConfig = .mpc(serviceType: self.serviceType,
                                             session: self.session,
                                             isHost: self.isPlayerHost)
                    }
                    self.showMatch(for: networkConfig, andHide: [])
                })
            case .cancel:
                self.dismiss(animated: true, completion: {
                    self.navigationController?.popToRootViewController(animated: false)
                })
            }
        }

        let nav = UINavigationController(rootViewController: controller)
        present(nav, animated: true, completion: nil)
    }

}
