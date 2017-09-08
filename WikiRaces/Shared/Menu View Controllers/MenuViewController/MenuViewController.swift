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

class MenuViewController: UIViewController {

    // MARK: - Properties

    var isMenuVisable = false

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

        //swiftlint:disable:next discarded_notification_center_observer line_length
        NotificationCenter.default.addObserver(forName: NSNotification.Name("PlayerQuit"), object: nil, queue: nil) { _ in
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: {
                    self.navigationController?.popToRootViewController(animated: false)
                })
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateMenuIn()

        #if MULTIWINDOWDEBUG
            performSegue(.debugBypass, isHost: view.window!.frame.origin == .zero)
        #else
            attemptGCAuthentication()
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
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

    @objc
    func joinRace() {
        animateMenuOut {
            self.performSegue(.showConnecting, isHost: false)
        }
    }

    @objc
    func createRace() {
        animateMenuOut {
            self.performSegue(.showConnecting, isHost: true)
        }
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

}
