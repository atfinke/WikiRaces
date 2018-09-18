//
//  MPCConnectViewController+UI.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MPCConnectViewController {

    // MARK: - Interface

    func setupInterface() {
        cancelButton.alpha = 0.0
        cancelButton.setAttributedTitle(NSAttributedString(string: "CANCEL", spacing: 1.5), for: .normal)

        updateDescriptionLabel(to: "CHECKING CONNECTION")
        descriptionLabel.alpha = 0.0

        activityIndicatorView.alpha = 0.0
        activityIndicatorView.color = UIColor.wkrActivityIndicatorColor
        view.backgroundColor = UIColor.wkrBackgroundColor

        inviteView.alpha = 0.0
        inviteView.backgroundColor = UIColor.wkrBackgroundColor
        inviteView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(inviteView)

        hostNameLabel.text = ""
        hostNameLabel.numberOfLines = 0
        hostNameLabel.textColor = UIColor.wkrLightTextColor
        hostNameLabel.textAlignment = .center
        hostNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        hostNameLabel.translatesAutoresizingMaskIntoConstraints = false
        inviteView.addSubview(hostNameLabel)

        acceptButton.setTitle("Accept", for: .normal)
        acceptButton.setTitleColor(UIColor(red: 0, green: 122.0/255.0, blue: 1.0, alpha: 1.0), for: .normal)
        acceptButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        acceptButton.translatesAutoresizingMaskIntoConstraints = false
        acceptButton.addTarget(self, action: #selector(acceptInvite), for: .touchUpInside)
        inviteView.addSubview(acceptButton)

        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(UIColor(red: 1, green: 0, blue: 0, alpha: 1.0), for: .normal)
        declineButton.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.addTarget(self, action: #selector(declineInvite), for: .touchUpInside)
        inviteView.addSubview(declineButton)

        setupConstraints()
    }

    private func setupConstraints() {
        let offset: CGFloat = 20
        let constraints = [
            inviteView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 10),
            inviteView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -10),
            inviteView.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10),

            hostNameLabel.leftAnchor.constraint(equalTo: inviteView.leftAnchor),
            hostNameLabel.rightAnchor.constraint(equalTo: inviteView.rightAnchor),
            hostNameLabel.topAnchor.constraint(equalTo: inviteView.topAnchor),

            declineButton.rightAnchor.constraint(equalTo: inviteView.centerXAnchor, constant: -offset),
            declineButton.topAnchor.constraint(equalTo: hostNameLabel.bottomAnchor, constant: 50),
            declineButton.bottomAnchor.constraint(lessThanOrEqualTo: inviteView.bottomAnchor),

            acceptButton.leftAnchor.constraint(equalTo: inviteView.centerXAnchor, constant: offset),
            acceptButton.topAnchor.constraint(equalTo: declineButton.topAnchor),
            acceptButton.bottomAnchor.constraint(equalTo: declineButton.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
