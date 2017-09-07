//
//  LobbyViewController+UI.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

extension LobbyViewController {

    // MARK: - Interface

    func setupInterface() {
        title = "CONNECTED PLAYERS"
        self.view = visualEffectView

        setupTableView()
        let overlayView = setupBottomOverlayView()

        let fakeWidth = tableView.widthAnchor.constraint(equalToConstant: 500)
        fakeWidth.priority = UILayoutPriority.defaultLow
        overlayHeightConstraint = overlayView.heightAnchor.constraint(equalToConstant: alertViewHeight)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: overlayView.topAnchor),
            tableView.leftAnchor.constraint(greaterThanOrEqualTo: visualEffectView.leftAnchor),
            tableView.rightAnchor.constraint(lessThanOrEqualTo: visualEffectView.rightAnchor),
            tableView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            tableView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fakeWidth,

            overlayView.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor),
            overlayView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            overlayHeightConstraint!
        ]

        NSLayoutConstraint.activate(constraints)
    }

    private func setupTableView() {
        tableView.sectionHeaderHeight = 0
        tableView.sectionFooterHeight = isPlayerHost ? 70 : 0

        tableView.contentOffset = .zero
        tableView.allowsSelection = false
        tableView.alwaysBounceVertical = false
        tableView.separatorColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        tableView.register(PlayerStateTableViewCell.self, forCellReuseIdentifier: playerCellReuseIdentifier)
        tableView.register(FooterButtonTableViewCell.self, forCellReuseIdentifier: footerCellReuseIdentifier)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.contentView.addSubview(tableView)
    }

    func setupBottomOverlayView() -> WKRUIBottomOverlayView {
        let bottomOverlayView = WKRUIBottomOverlayView()
        bottomOverlayView.translatesAutoresizingMaskIntoConstraints = false
        bottomOverlayView.clipsToBounds = true
        visualEffectView.contentView.addSubview(bottomOverlayView)

        startButton.isHidden = true
        startButton.title = "Start Race"
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startRaceButtonPressed), for: UIControlEvents.touchUpInside)
        bottomOverlayView.contentView.addSubview(startButton)

        overlayLabel.textAlignment = .center
        overlayLabel.adjustsFontSizeToFitWidth = true
        overlayLabel.translatesAutoresizingMaskIntoConstraints = false
        let string = isPlayerHost ? "INVITE PLAYERS TO RACE" : "WAITING FOR HOST"
        overlayLabel.attributedText = NSAttributedString(string: string,
                                                  spacing: 2.0,
                                                  font: UIFont.systemFont(ofSize: 19.0))
        bottomOverlayView.contentView.addSubview(overlayLabel)

        let constraints = [
            startButton.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 250),
            startButton.heightAnchor.constraint(equalToConstant: 40),

            overlayLabel.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            overlayLabel.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            overlayLabel.widthAnchor.constraint(equalTo: bottomOverlayView.widthAnchor),
            overlayLabel.heightAnchor.constraint(equalTo: bottomOverlayView.heightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        return bottomOverlayView
    }

}
