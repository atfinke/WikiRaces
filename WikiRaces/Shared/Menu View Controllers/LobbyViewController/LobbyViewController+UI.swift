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

        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = .clear

        setupTableView()
        let overlayView = setupBottomOverlayView()

        let fakeWidth = tableView.widthAnchor.constraint(equalToConstant: 500)
        fakeWidth.priority = UILayoutPriority.defaultLow
        overlayHeightConstraint = overlayView.heightAnchor.constraint(equalToConstant: 0)

        descriptionLabel.textAlignment = .center
        descriptionLabel.font = UIFont(monospaceSize: 20.0)
        descriptionLabel.adjustsFontSizeToFitWidth = true
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        let string = isPlayerHost ? "INVITE PLAYERS TO RACE" : "WAITING FOR HOST"
        descriptionLabel.attributedText = NSAttributedString(string: string,
                                                             spacing: 2.0,
                                                             font: UIFont.systemFont(ofSize: 19.0))
        view.addSubview(descriptionLabel)

        let constraints = [
            tableView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: overlayView.topAnchor),
            tableView.leftAnchor.constraint(greaterThanOrEqualTo: view.leftAnchor),
            tableView.rightAnchor.constraint(lessThanOrEqualTo: view.rightAnchor),
            tableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            tableView.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            fakeWidth,

            overlayView.leftAnchor.constraint(equalTo: view.leftAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlayHeightConstraint!,

            descriptionLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
            descriptionLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
            descriptionLabel.bottomAnchor.constraint(equalTo: overlayView.topAnchor),
            descriptionLabel.heightAnchor.constraint(equalToConstant: 50)
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

        view.addSubview(tableView)
    }

    func setupBottomOverlayView() -> WKRUIBottomOverlayView {
        let bottomOverlayView = WKRUIBottomOverlayView()
        bottomOverlayView.translatesAutoresizingMaskIntoConstraints = false
        bottomOverlayView.clipsToBounds = true
        view.addSubview(bottomOverlayView)

        startButton.isHidden = true
        startButton.title = "Start Race"
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startRaceButtonPressed), for: UIControlEvents.touchUpInside)
        bottomOverlayView.contentView.addSubview(startButton)

        let constraints = [
            startButton.centerXAnchor.constraint(equalTo: bottomOverlayView.centerXAnchor),
            startButton.centerYAnchor.constraint(equalTo: bottomOverlayView.centerYAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 250),
            startButton.heightAnchor.constraint(equalToConstant: 40)
         ]
        NSLayoutConstraint.activate(constraints)
        return bottomOverlayView
    }

}
