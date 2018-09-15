//
//  DebugInfoTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

class DebugInfoTableViewCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "reuseIdentifier"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

        guard let textLabel = textLabel, let detailTextLabel = detailTextLabel else { fatalError() }

        textLabel.removeConstraints(textLabel.constraints)
        detailTextLabel.removeConstraints(detailTextLabel.constraints)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        detailTextLabel.translatesAutoresizingMaskIntoConstraints = false

        textLabel.numberOfLines = 0
        detailTextLabel.numberOfLines = 0

        let leftMarginConstraint = NSLayoutConstraint(item: textLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        let rightMarginConstraint = NSLayoutConstraint(item: textLabel,
                                                       attribute: .right,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .rightMargin,
                                                       multiplier: 1.0,
                                                       constant: 0.0)

        let verticalConstant: CGFloat = 12.0
        let constraints = [
            leftMarginConstraint,
            rightMarginConstraint,
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: verticalConstant),
            textLabel.bottomAnchor.constraint(equalTo: detailTextLabel.topAnchor),

            detailTextLabel.leftAnchor.constraint(equalTo: textLabel.leftAnchor),
            detailTextLabel.rightAnchor.constraint(equalTo: textLabel.rightAnchor),
            detailTextLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalConstant)
        ]

        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
