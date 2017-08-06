//
//  PlayersViewController+UI.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

extension PlayersViewController {

    // MARK: - Interface

    func setupInterface() {
        title = "CONNECTED PLAYERS"
        self.view = visualEffectView

        setupTableView()
        let overlayView = setupBottomOverlayView()

        let overlayHeight = isPlayerHost ? 70 : alertViewHeight
        let fakeWidth = tableView.widthAnchor.constraint(equalToConstant: 500)
        fakeWidth.priority = UILayoutPriority.defaultLow

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: overlayView.topAnchor),
            tableView.leftAnchor.constraint(greaterThanOrEqualTo: visualEffectView.leftAnchor),
            tableView.rightAnchor.constraint(lessThanOrEqualTo: visualEffectView.rightAnchor),
            tableView.centerXAnchor.constraint(equalTo: visualEffectView.centerXAnchor),
            tableView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fakeWidth,

            overlayView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            overlayView.leftAnchor.constraint(equalTo: visualEffectView.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: visualEffectView.rightAnchor),
            overlayView.heightAnchor.constraint(equalToConstant: isPreMatch ? overlayHeight : 0)
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

        let button = WKRUIButton()
        button.isHidden = !isPlayerHost
        button.title = "Start Race"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startRaceButtonPressed), for: UIControlEvents.touchUpInside)
        bottomOverlayView.contentView.addSubview(button)

        let label = UILabel()
        label.isHidden = isPlayerHost
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.attributedText = NSAttributedString(string: "WAITING FOR HOST", spacing: 2.0)
        bottomOverlayView.contentView.addSubview(label)

        let constraints = [
            button.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 250),
            button.heightAnchor.constraint(equalToConstant: 40),

            label.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 250),
            label.heightAnchor.constraint(equalToConstant: 40)
        ]
        NSLayoutConstraint.activate(constraints)

        return bottomOverlayView
    }

}

