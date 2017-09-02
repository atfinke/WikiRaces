//
//  PlayerStateTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import UIKit
import WKRKit

class PlayerStateTableViewCell: UITableViewCell {

    // MARK: - Properties

    private let nameLabel = UILabel()
    private let stateLabel = UILabel()
    private let stackView = UIStackView()

    var player: WKRPlayer? {
        didSet {
            nameLabel.text = player?.name
        }
    }

    var state: WKRPlayerState? {
        didSet {
            if state?.connected ?? false {
                stateLabel.text = "Connected"
            } else {
                stateLabel.text = state?.text
            }
        }
    }

    // MARK: - Initialization

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        nameLabel.textColor = UIColor.wkrTextColor
        stateLabel.textColor = UIColor.wkrLightTextColor
        nameLabel.font = UIFont.systemFont(ofSize: 20.0, weight: UIFont.Weight.medium)
        stateLabel.font = UIFont.systemFont(ofSize: 18.0, weight: UIFont.Weight.regular)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.spacing = 10.0
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(stateLabel)
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 15)
        stackView.isLayoutMarginsRelativeArrangement = true

        addSubview(stackView)

        let constraints = [
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
