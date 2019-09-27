//
//  MPCHostPeerStateCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

internal class MPCHostPeerStateCell: UITableViewCell {

    // MARK: - Properties

    let peerLabel = UILabel()
    let detailLabel = UILabel()

    static let reuseIdentifier = "reuseIdentifier"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        peerLabel.textAlignment = .left
        peerLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        peerLabel.numberOfLines = 0
        peerLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(peerLabel)

        detailLabel.textAlignment = .right
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        let leftMarginConstraint = NSLayoutConstraint(item: peerLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        let rightMarginConstraint = NSLayoutConstraint(item: detailLabel,
                                                       attribute: .right,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .rightMargin,
                                                       multiplier: 1.0,
                                                       constant: 0.0)

       let constraints = [
            leftMarginConstraint,
            peerLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            peerLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 25),
            peerLabel.rightAnchor.constraint(lessThanOrEqualTo: detailLabel.leftAnchor,
                                             constant: -10),
            peerLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            rightMarginConstraint,
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        peerLabel.textColor = textColor
        detailLabel.textColor = textColor
    }

}
