//
//  MPCHostAutoInviteCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 11/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

final internal class MPCHostAutoInviteCell: UITableViewCell {

    // MARK: - Properties

    var onToggle: ((Bool) -> Void)?
    var isEnabled: Bool = false {
        didSet {
            toggle.isOn = isEnabled
            onToggle?(isEnabled)
        }
    }

    private let detailLabel = UILabel()
    private let toggle = UISwitch()

    static let reuseIdentifier = "hostAutoInviteCell"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none

        detailLabel.text = "Auto-Invite"
        detailLabel.textAlignment = .left
        detailLabel.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        detailLabel.numberOfLines = 0
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(detailLabel)

        toggle.addTarget(self, action: #selector(toggled), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        addSubview(toggle)

        let leftMarginConstraint = NSLayoutConstraint(item: detailLabel,
                                                      attribute: .left,
                                                      relatedBy: .equal,
                                                      toItem: self,
                                                      attribute: .leftMargin,
                                                      multiplier: 1.0,
                                                      constant: 0.0)

        let rightMarginConstraint = NSLayoutConstraint(item: toggle,
                                                       attribute: .right,
                                                       relatedBy: .equal,
                                                       toItem: self,
                                                       attribute: .rightMargin,
                                                       multiplier: 1.0,
                                                       constant: 0.0)

        let constraints = [
            leftMarginConstraint,
            detailLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            detailLabel.rightAnchor.constraint(lessThanOrEqualTo: toggle.leftAnchor,
                                             constant: -10),
            detailLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),

            rightMarginConstraint,
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor)
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
        toggle.onTintColor = textColor
        detailLabel.textColor = textColor
    }

    // MARK: - Helpers -

    @objc
    func toggled() {
        isEnabled = toggle.isOn
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
