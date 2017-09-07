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
    var isFadingInElements = true

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
        peerID = MCPeerID(displayName: playerName)

        cancelButton.setAttributedTitle(NSAttributedString(string: "CANCEL", spacing: 1.5), for: .normal)
        descriptionLabel.attributedText = NSAttributedString(string: "CHECKING CONNECTION", spacing: 2.0)

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

        WKRConnectionTester.start { (success) in
            DispatchQueue.main.async {
                if success {
                    if self.isPlayerHost {
                        self.showMatch(isPlayerHost: true)
                    } else {
                        self.startAdvertising()
                    }
                } else {
                    self.showConnectionError()
                }
            }
        }

        guard isFadingInElements else {
            return
        }

        isFadingInElements = false
        UIView.animate(withDuration: 0.5, animations: {
            self.descriptionLabel.alpha = 1.0
            self.activityIndicatorView.alpha = 1.0
            self.cancelButton.alpha = 1.0
        })
    }

    func showConnectionError() {
        descriptionLabel.attributedText = NSAttributedString(string: "FAILED TO CONNECT", spacing: 2.0)
        UIView.animate(withDuration: 0.5, animations: {
            self.activityIndicatorView.alpha = 0.0
            self.cancelButton.alpha = 0.0
        })

        //swiftlint:disable:next line_length
        let alertController = UIAlertController(title: "Internet Not Reachable", message: "A fast internet connection is required to play WikiRaces.", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { _ in
            UIView.animate(withDuration: 0.25, animations: {
                self.descriptionLabel.alpha = 0.0
                self.activityIndicatorView.alpha = 0.0
                self.cancelButton.alpha = 0.0
            }, completion: { _ in
                self.navigationController?.popToRootViewController(animated: false)
            })
        }
        alertController.addAction(action)
        present(alertController, animated: true, completion: nil)
    }

    func showMatch(isPlayerHost: Bool) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25, animations: {
                self.descriptionLabel.alpha = 0.0
                self.activityIndicatorView.alpha = 0.0
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
            self.activityIndicatorView.alpha = 0.0
            self.cancelButton.alpha = 0.0
        }, completion: { _ in
            self.navigationController?.presentingViewController?.dismiss(animated: true, completion: nil)
        })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = (segue.destination as? UINavigationController)?
            .rootViewController as? GameViewController,
            let isPlayerHost = sender as? Bool else {
                fatalError()
        }
        destination.session = session
        destination.serviceType = serviceType
        destination.isPlayerHost = isPlayerHost
    }

}
