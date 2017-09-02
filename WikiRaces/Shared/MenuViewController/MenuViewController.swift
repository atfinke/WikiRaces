//
//  MenuViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit

import WKRKit
import WKRUIKit

import MultipeerConnectivity

class MenuViewController: UIViewController {

    // MARK: - Properties

    let topView = UIView()
    let bottomView = UIView()

    let createButton = WKRUIButton()
    let puzzleView = UIScrollView()

    var puzzleTimer: Timer?
    var bottomViewAnchorConstraint: NSLayoutConstraint!

    var advertiser: MCNearbyServiceAdvertiser?

    let peerID = MCPeerID(displayName: UIDevice.current.name)
    let serviceType = "WKRPeer30"

    lazy var session: MCSession = {
        return MCSession(peer: self.peerID)
    }()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMenuIn()

        #if MULTIWINDOWDEBUG
            tempIsHost = view.window!.frame.origin == .zero
            self.performSegue(withIdentifier: "showConnecting", sender: false)
        #endif
    }

    // MARK: - Actions

    @IBAction func advertise(_ sender: Any) {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    @IBAction func browse(_ sender: Any) {
        let browser = MCBrowserViewController(serviceType: serviceType, session: session)
        browser.delegate = self
        present(browser, animated: true, completion: nil)
    }

    // MARK: - Other

    func startSession(isHost: Bool) {
        tempIsHost = isHost
        self.performSegue(withIdentifier: "showConnecting", sender: false)
    }

    @objc
    func createButtonPressed() {
        /*animateMenuOut {
         DispatchQueue.main.async {
         let vc = _ConnectViewController()
         self.present(vc, animated: true, completion: nil)
         vc.startMultipeer(isHost: true)
         }
         self.performSegue(withIdentifier: "showConnecting", sender: true)
         }*/
    }

    // MARK: - Menu Animations

    func animateMenuOut(completion: (() -> Void)?) {
        createButton.isEnabled = false
        bottomViewAnchorConstraint.constant = bottomView.frame.height

        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
            self.topView.alpha = 0.0
        }, completion: { _ in
            self.puzzleTimer?.invalidate()
            completion?()
        })
    }

    func animateMenuIn() {
        puzzleTimer?.invalidate()
        puzzleTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.puzzleView.contentOffset = CGPoint(x: self.puzzleView.contentOffset.x + 0.5, y: 0)
        }
        bottomViewAnchorConstraint.constant = 0

        UIView.animate(withDuration: 0.75, animations: {
            self.view.layoutIfNeeded()
            self.topView.alpha = 1.0
        }, completion: { _ in
            self.createButton.isEnabled = true
        })
    }

    // MARK: - Fonts

    func titleLabelFont() -> UIFont {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIFont.boldSystemFont(ofSize: 55)
        } else {
            return UIFont.boldSystemFont(ofSize: 37)
        }
    }

    func descriptionLabelFont() -> UIFont {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIFont.systemFont(ofSize: 30, weight: UIFont.Weight.medium)
        } else {
            return UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.medium)
        }
    }

    func descriptionLabelConstants() -> (topAnchorConstant: CGFloat, heightConstant: CGFloat) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return (-20, 140)
        } else {
            return (0, 70)
        }
    }

    /*override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     if segue.identifier == "showConnecting", let isHost = sender as? Bool {
     guard let navController = segue.destination as? UINavigationController else { fatalError() }
     guard let controller = navController.rootViewController as? ConnectingViewController else { fatalError() }
     controller.hostMode = isHost
     }
     }*/

    var tempIsHost: Bool!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = (segue.destination as? UINavigationController)?
            .rootViewController as? GameViewController else {
                fatalError()
        }

        #if MULTIWINDOWDEBUG
            //swiftlint:disable:next force_cast
            destination._playerName = (view.window as! DebugWindow).playerName
        #else
            destination.session = session
        #endif

        destination.isPlayerHost = tempIsHost
    }

}
