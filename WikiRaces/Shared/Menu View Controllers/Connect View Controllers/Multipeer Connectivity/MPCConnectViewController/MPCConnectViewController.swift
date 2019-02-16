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
    var invites = [(handler: ((Bool, MCSession) -> Void)?, host: MCPeerID, context: MPCHostContext?)]()

    var peerID: MCPeerID!
    var hostPeerID: MCPeerID?

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
            PlayerMetrics.log(event: .nameType, attributes: ["Type": "CustomName"])
        } else if GKLocalPlayer.local.isAuthenticated {
            playerName = GKLocalPlayer.local.alias
            PlayerMetrics.log(event: .nameType, attributes: ["Type": "GCAlias"])
        } else {
            PlayerMetrics.log(event: .nameType, attributes: ["Type": "DeviceName"])
        }

        #if !MULTIWINDOWDEBUG
        Crashlytics.sharedInstance().setUserName(playerName)
        #endif

        isValidPlayerName = playerName.utf8.count < 40
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
        advertiser?.stopAdvertisingPeer()

        // Reject all the pending invites
        for invite in invites {
            invite.handler?(false, session)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard isFirstAppear else {
            return
        }
        isFirstAppear = false

        // Test the connection to Wikipedia
        runConnectionTest { success in
            if success && self.isValidPlayerName {
                if self.isPlayerHost {
                    self.toggleCoreInterface(isHidden: true,
                                        duration: 0.25,
                                        and: [self.inviteView],
                                        completion: {
                                            self.performSegue(withIdentifier: "showHost", sender: nil)
                    })
                } else {
                    self.startAdvertising()
                }
            } else if !success {
                self.showError(title: "Slow Connection",
                               message: "A fast internet connection is required to play WikiRaces.")
            }
        }

        toggleCoreInterface(isHidden: false, duration: 0.5)

        if !isValidPlayerName {
            showError(title: "Player Name Too Long",
                      message: "Your player name is too long. Would you like to open settings to adjust it?",
                      showSettingsButton: true)
        }
    }

    // MARK: - State Changes

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else {
            fatalError("Destination is not a UINavigationController")
        }

        if segue.identifier == "showHost" {
            guard let destination = navigationController.rootViewController as? MPCHostViewController else {
                fatalError("Destination rootViewController is not a MPCHostViewController")
            }
            destination.peerID = peerID
            destination.session = session
            destination.serviceType = serviceType
            destination.didStartMatch = { [weak self] isSolo in
                guard let self = self else { return }
                self.isSolo = isSolo
                self.dismiss(animated: true, completion: {
                    self.showMatch(isPlayerHost: true,
                                  generateFeedback: false,
                                  andHide: [self.inviteView])
                })
            }
            destination.didCancelMatch = { [weak self] in
                self?.dismiss(animated: true, completion: {
                    self?.navigationController?.popToRootViewController(animated: false)
                })
            }
        } else {
            guard let destination = navigationController.rootViewController as? GameViewController,
                let isPlayerHost = sender as? Bool else {
                    fatalError("Destination rootViewController is not a GameViewController")
            }
            if isSolo {
                destination.networkConfig = .solo(name: playerName)
            } else {
                destination.networkConfig = .mpc(serviceType: serviceType,
                                                 session: session,
                                                 isHost: isPlayerHost)
            }
        }
    }

}
