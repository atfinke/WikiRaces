//
//  VotingTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import UIKit
import WKRKit

internal class VotingTableViewCell: UITableViewCell {

    // MARK: - Properties

    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let stackView = UIStackView()

    // MARK: - Property Observers

    override var isSelected: Bool {
        didSet {
            if isSelected {
                countLabel.textColor = UIColor.wkrVoteCountSelectedTextColor
                countLabel.font = UIFont.systemFont(ofSize: 20)
            } else {
                countLabel.textColor = UIColor.wkrVoteCountTextColor
                countLabel.font = UIFont.systemFont(ofSize: 17)
            }
        }
    }

    var vote: (page: WKRPage, votes: Int)? {
        didSet {
            if let vote = vote {
                titleLabel.text = vote.page.title
                countLabel.text = vote.votes.description
            } else {
                titleLabel.text = "UNKNOWN ERROR"
                countLabel.text = "0"
            }
        }
    }

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = UIColor.clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.alignment = .center

        titleLabel.textColor = UIColor.wkrTextColor
        titleLabel.text = ""
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 17)

        countLabel.text = "0"
        countLabel.textAlignment = .right
        countLabel.textColor = UIColor.wkrVoteCountTextColor
        countLabel.font = UIFont.systemFont(ofSize: 20)

        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(countLabel)

        addSubview(stackView)

        let constraints = [
            stackView.leftAnchor.constraint(equalTo: leftAnchor),
            stackView.rightAnchor.constraint(equalTo: rightAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
