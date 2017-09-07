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

    var advertiser: MCNearbyServiceAdvertiser?
    var isMenuVisable = false

    let peerID = MCPeerID(displayName: UIDevice.current.name)
    let serviceType = "WKRPeer30"

    lazy var session: MCSession = {
        return MCSession(peer: self.peerID)
    }()

    // MARK: - Interface Elements

    let topView = UIView()
    let bottomView = UIView()

    let titleLabel = UILabel()
    let subtitleLabel = UILabel()

    let joinButton = WKRUIButton()
    let createButton = WKRUIButton()

    var leftMenuTile: MenuTile?
    var middleMenuTile: MenuTile?
    var rightMenuTile: MenuTile?

    var puzzleTimer: Timer?
    let puzzleView = UIScrollView()

    // MARK: - Constraints

    var topViewLeftConstraint: NSLayoutConstraint!
    var bottomViewAnchorConstraint: NSLayoutConstraint!

    var titleLabelConstraint: NSLayoutConstraint!
    var joinButtonWidthConstraint: NSLayoutConstraint!
    var joinButtonHeightConstraint: NSLayoutConstraint!
    var createButtonWidthConstraint: NSLayoutConstraint!
    var createButtonHeightConstraint: NSLayoutConstraint!

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupInterface()

        let versionGesture = UITapGestureRecognizer(target: self, action: #selector(showVersionInfo))
        versionGesture.numberOfTapsRequired = 2
        versionGesture.numberOfTouchesRequired = 2
        view.addGestureRecognizer(versionGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMenuIn()

        #if MULTIWINDOWDEBUG
            tempIsHost = view.window!.frame.origin == .zero
            self.performSegue(withIdentifier: "showConnecting", sender: false)
        #else
            attemptGCAuthentication()
        #endif
    }

    // MARK: - Actions

    @objc
    func showVersionInfo() {
        guard let bundleVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let bundleShortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            fatalError()
        }
        let appVersion = bundleShortVersion + " (\(bundleVersion)) / "
        titleLabel.text = appVersion + "\(WKRKitConstants.version) / \(WKRUIConstants.version)"
    }

    @IBAction func advertise(_ sender: Any) {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    @IBAction func browse(_ sender: Any) {
        animateMenuOut {
            let browser = MCBrowserViewController(serviceType: self.serviceType, session: self.session)
            browser.delegate = self
            self.present(browser, animated: true, completion: nil)
        }
    }

    // MARK: - Other

    func startSession(isHost: Bool) {
        tempIsHost = isHost
        self.performSegue(withIdentifier: "showConnecting", sender: false)
    }

    // MARK: - Menu Animations

    func animateMenuOut(completion: (() -> Void)?) {
        view.isUserInteractionEnabled = false
        bottomViewAnchorConstraint.constant = bottomView.frame.height

        isMenuVisable = false
        view.setNeedsLayout()

        UIView.animate(withDuration: 0.75, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.puzzleTimer?.invalidate()
            completion?()
        })
    }

    func animateMenuIn() {
        view.isUserInteractionEnabled = false

        puzzleTimer?.invalidate()
        puzzleTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            self.puzzleView.contentOffset = CGPoint(x: self.puzzleView.contentOffset.x + 0.5, y: 0)
        }

        isMenuVisable = true
        view.setNeedsLayout()

        UIView.animate(withDuration: 0.75, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.view.isUserInteractionEnabled = true
        })
    }

    // MARK: - Fonts

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
