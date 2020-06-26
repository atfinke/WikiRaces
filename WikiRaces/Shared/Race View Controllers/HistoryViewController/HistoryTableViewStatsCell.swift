//
//  HistoryTableViewStatsCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/28/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

final internal class HistoryTableViewStatsCell: UITableViewCell {

    // MARK: - Properties -

    static let reuseIdentifier = "statsReuseIdentifier"

    var stat: (key: String, value: String)? {
        didSet {
            statLabel.text = stat?.key
            detailLabel.text = stat?.value
        }
    }

    let statLabel = UILabel()
    let detailLabel = UILabel()

    // MARK: - Initialization -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        statLabel.textAlignment = .left
        statLabel.font = UIFont.systemRoundedFont(ofSize: 17, weight: .regular)
        statLabel.numberOfLines = 0
        statLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statLabel)

        detailLabel.font = UIFont.systemRoundedFont(ofSize: 17, weight: .medium)
        detailLabel.textAlignment = .right
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        setupConstraints()
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        tintColor = textColor
        statLabel.textColor = textColor
        detailLabel.textColor = textColor
    }

    // MARK: - Constraints -

    private func setupConstraints() {
        let leftMarginConstraint = NSLayoutConstraint(item: statLabel,
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
            statLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            statLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 15),
            statLabel.rightAnchor.constraint(lessThanOrEqualTo: detailLabel.leftAnchor, constant: -15),

            rightMarginConstraint,
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }

}
