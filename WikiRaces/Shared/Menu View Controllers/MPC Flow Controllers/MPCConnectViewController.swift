//
//  MPCConnectViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/6/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit
import MultipeerConnectivity

import WKRKit
import WKRUIKit

class MPCConnectViewController: StateLogViewController {

    // MARK: - Interafce Elements

    /// View that contains accept/cancel buttons, sender label
    @IBOutlet weak var inviteView: UIView!
    /// Shows the sender of the invie
    @IBOutlet weak var senderLabel: UILabel!
    /// The button to cancel joining/creating a race
    @IBOutlet weak var cancelButton: UIButton!
    /// General status label
    @IBOutlet weak var descriptionLabel: UILabel!
    /// Activity spinner
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: - Properties

    var isPlayerHost = false
    var isShowingInvite = false
    var isValidPlayerName = false

    var isFirstAppear = true
    var isShowingMatch = false

    // MARK: - MPC Properties

    var advertiser: MCNearbyServiceAdvertiser?
    var activeInvite: ((Bool, MCSession) -> Void)?
    var invites = [(handler: ((Bool, MCSession) -> Void)?, host: MCPeerID)]()

    var peerID: MCPeerID!
    var hostPeerID: MCPeerID?

    let serviceType = "WKRPeer30"
    lazy var session: MCSession = {
        return MCSession(peer: self.peerID)
    }()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Gets either the player name specified in settings.app, then GK alias, the device name
        var playerName = UIDevice.current.name
        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            playerName = name
            PlayerAnalytics.log(event: .usingCustomName(playerName))
        } else if GKLocalPlayer.localPlayer().isAuthenticated, let alias = GKLocalPlayer.localPlayer().alias {
            playerName = alias
            PlayerAnalytics.log(event: .usingGCAlias(playerName))
        } else {
            PlayerAnalytics.log(event: .usingDeviceName(playerName))
        }
        Crashlytics.sharedInstance().setUserName(playerName)

        cancelButton.setAttributedTitle(NSAttributedString(string: "CANCEL", spacing: 1.5), for: .normal)
        descriptionLabel.attributedText = NSAttributedString(string: "CHECKING CONNECTION",
                                                             spacing: 2.0,
                                                             font: UIFont.systemFont(ofSize: 18.0, weight: .medium))

        cancelButton.alpha = 0.0
        activityIndicatorView.alpha = 0.0
        inviteView.alpha = 0.0
        descriptionLabel.alpha = 0.0

        isValidPlayerName = [UInt8](playerName.utf8).count < 40
        guard isValidPlayerName else { return }

        // Uses existing peer ID object if already created (recommended per Apple docs)
        if let pastPeerIDData = UserDefaults.standard.data(forKey: "PeerID"),
            let lastPeerID = NSKeyedUnarchiver.unarchiveObject(with: pastPeerIDData) as? MCPeerID,
            lastPeerID.displayName == playerName {
            peerID = lastPeerID
        } else {
            peerID = MCPeerID(displayName: playerName)
            let data = NSKeyedArchiver.archivedData(withRootObject: peerID)
            UserDefaults.standard.set(data, forKey: "PeerID")
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
        WKRConnectionTester.start { (success) in
            DispatchQueue.main.async {
                if success && self.isValidPlayerName {
                    if self.isPlayerHost {
                        UIView.animate(withDuration: 0.25, animations: {
                            self.descriptionLabel.alpha = 0.0
                            self.inviteView.alpha = 0.0
                            self.cancelButton.alpha = 0.0
                            self.activityIndicatorView.alpha = 0.0
                        }, completion: { _ in
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
        }

        UIView.animate(withDuration: 0.5, animations: {
            self.descriptionLabel.alpha = 1.0
            self.activityIndicatorView.alpha = 1.0
            self.cancelButton.alpha = 1.0
        })

        if !isValidPlayerName {
            showError(title: "Player Name Too Long",
                      message: "Your player name is too long. Would you like to open settings to adjust it?",
                      showSettingsButton: true)
        }
    }

    // MARK: - Interface Updates

    /// Shows an error with a title
    ///
    /// - Parameters:
    ///   - title: The title of the error message
    ///   - message: The message body of the error
    func showError(title: String, message: String, showSettingsButton: Bool = false) {
        if isValidPlayerName {
            self.session.delegate = nil
            self.session.disconnect()
        }

        UIView.animate(withDuration: 0.5, animations: {
            self.activityIndicatorView.alpha = 0.0
            self.cancelButton.alpha = 0.0
        })

        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Menu", style: .default) { _ in
            self.pressedCancelButton()
        }
        alertController.addAction(action)

        if showSettingsButton {
            let settingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
                PlayerAnalytics.log(event: .userAction("showError:settings"))
                UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!,
                                          options: [:], completionHandler: nil)
                self.pressedCancelButton()
            })
            alertController.addAction(settingsAction)
        }

        present(alertController, animated: true, completion: nil)
        PlayerAnalytics.log(presentingOf: alertController, on: self)
    }

    /// Prepares to start the match
    ///
    /// - Parameter isPlayerHost: Is the local player is host
    func showMatch(isPlayerHost: Bool) {
        guard !isShowingMatch else { return }
        isShowingMatch = true

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.descriptionLabel.alpha = 0.0
                self.inviteView.alpha = 0.0
                self.cancelButton.alpha = 0.0
                self.activityIndicatorView.alpha = 0.0
            }, completion: { _ in
                self.performSegue(withIdentifier: "showRace", sender: isPlayerHost)
            })
        }
    }

    /// Cancels the join/create a race action and sends player back to main menu
    @IBAction func pressedCancelButton() {
        PlayerAnalytics.log(event: .userAction(#function))
        UIView.animate(withDuration: 0.25, animations: {
            self.descriptionLabel.alpha = 0.0
            self.inviteView.alpha = 0.0
            self.activityIndicatorView.alpha = 0.0
            self.cancelButton.alpha = 0.0
        }, completion: { _ in
            self.navigationController?.popToRootViewController(animated: false)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationController = segue.destination as? UINavigationController else {
            fatalError()
        }

        if segue.identifier == "showHost" {
            guard let destination = navigationController.rootViewController as? MPCHostViewController else {
                fatalError()
            }
            destination.peerID = peerID
            destination.session = session
            destination.serviceType = serviceType
            destination.didStartMatch = { [weak self] in
                self?.dismiss(animated: true, completion: {
                    self?.showMatch(isPlayerHost: true)
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
                    fatalError()
            }
            destination.session = session
            destination.serviceType = serviceType
            destination.isPlayerHost = isPlayerHost
        }
    }

}
