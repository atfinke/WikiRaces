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

class MPCConnectViewController: UIViewController {

    // MARK: - Interafce Elements

    @IBOutlet weak var inviteView: UIView!
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!

    // MARK: - Properties

    var isPlayerHost = false
    var isShowingInvite = false

    var isFirstAppear = true
    var isShowingMatch = false

    // MARK: - MPC Properties

    var advertiser: MCNearbyServiceAdvertiser?
    var activeInvite: ((Bool, MCSession) -> Void)?
    var invites = [(handler: ((Bool, MCSession) -> Void)?, host: String)]()

    var peerID: MCPeerID!

    let serviceType = "WKRPeer30"
    lazy var session: MCSession = {
        return MCSession(peer: self.peerID)
    }()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        var playerName = UIDevice.current.name
        if let name = UserDefaults.standard.object(forKey: "name_preference") as? String {
            playerName = name
        } else if GKLocalPlayer.localPlayer().isAuthenticated, let alias = GKLocalPlayer.localPlayer().alias {
            playerName = alias
        }

        if let pastPeerIDData = UserDefaults.standard.data(forKey: "PeerID"),
            let lastPeerID = NSKeyedUnarchiver.unarchiveObject(with: pastPeerIDData) as? MCPeerID,
            lastPeerID.displayName == playerName {
            peerID = lastPeerID
        } else {
            peerID = MCPeerID(displayName: playerName)
            let data = NSKeyedArchiver.archivedData(withRootObject: peerID)
            UserDefaults.standard.set(data, forKey: "PeerID")
        }

        cancelButton.setAttributedTitle(NSAttributedString(string: "CANCEL", spacing: 1.5), for: .normal)
        descriptionLabel.attributedText = NSAttributedString(string: "CHECKING CONNECTION",
                                                             spacing: 2.0,
                                                             font: UIFont.systemFont(ofSize: 18.0, weight: .medium))

        cancelButton.alpha = 0.0
        activityIndicatorView.alpha = 0.0
        inviteView.alpha = 0.0
        descriptionLabel.alpha = 0.0
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        advertiser?.stopAdvertisingPeer()

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

        WKRConnectionTester.start { (success) in
            DispatchQueue.main.async {
                if success {
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
                } else {
                    self.showConnectionError()
                }
            }
        }

        UIView.animate(withDuration: 0.5, animations: {
            self.descriptionLabel.alpha = 1.0
            self.activityIndicatorView.alpha = 1.0
            self.cancelButton.alpha = 1.0
        })
    }

    // MARK: - Interface Updates

    func showConnectionError() {
        descriptionLabel.attributedText = NSAttributedString(string: "FAILED TO CONNECT",
                                                             spacing: 2.0,
                                                             font: UIFont.systemFont(ofSize: 18.0, weight: .medium))
        UIView.animate(withDuration: 0.5, animations: {
            self.activityIndicatorView.alpha = 0.0
            self.cancelButton.alpha = 0.0
        })

        //swiftlint:disable:next line_length
        let alertController = UIAlertController(title: "Internet Not Reachable", message: "A fast internet connection is required to play WikiRaces.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            self.pressedCancelButton()
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func showMatch(isPlayerHost: Bool) {
        guard !isShowingMatch else { return }
        isShowingMatch = true

        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.05) {
                self.activityIndicatorView.alpha = 0.0
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.descriptionLabel.alpha = 0.0
                self.inviteView.alpha = 0.0
                self.cancelButton.alpha = 0.0
            }, completion: { _ in
                self.activityIndicatorView.stopAnimating()
                self.performSegue(withIdentifier: "showRace", sender: isPlayerHost)
            })
        }
    }

    @IBAction func pressedCancelButton() {
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
