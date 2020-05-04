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

final internal class VotingTableViewCell: PointerInteractionTableViewCell {

    // MARK: - Properties -

    private let titleLabel = UILabel()
    private let countLabel = UILabel()

    // MARK: - Property Observers -

    override var isSelected: Bool {
        didSet {
            if isSelected {
                countLabel.font = UIFont.systemFont(ofSize: 22, weight: .medium)
            } else {
                countLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            }
            setNeedsLayout()
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

    // MARK: - Initialization -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        backgroundColor = UIColor.clear

        titleLabel.numberOfLines = 0
        titleLabel.text = ""
        titleLabel.textAlignment = .left
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)

        countLabel.text = "0"
        countLabel.textAlignment = .right
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)

        let leftMarginConstraint = NSLayoutConstraint(item: titleLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        let rightMarginConstraint = NSLayoutConstraint(item: countLabel,
                                                   attribute: .right,
                                                   relatedBy: .equal,
                                                   toItem: self,
                                                   attribute: .rightMargin,
                                                   multiplier: 1.0,
                                                   constant: 0.0)
        let constraints = [
            leftMarginConstraint,
            rightMarginConstraint,

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            titleLabel.rightAnchor.constraint(equalTo: countLabel.rightAnchor, constant: -20),

            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - View Life Cycle -

    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel.textColor = .wkrTextColor(for: traitCollection)
        if isSelected {
            countLabel.textColor = .wkrVoteCountSelectedTextColor(for: traitCollection)
        } else {
            countLabel.textColor = .wkrVoteCountTextColor(for: traitCollection)
        }
    }

}
