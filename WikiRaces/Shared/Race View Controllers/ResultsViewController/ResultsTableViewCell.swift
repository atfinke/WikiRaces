//
//  ResultsTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

class ResultsTableViewCell: UITableViewCell {

    // MARK: - Properties

    let playerLabel = UILabel()
    let detailLabel = UILabel()

    var isShowingActivityIndicatorView: Bool = false {
        didSet {
            detailLabel.isHidden = isShowingActivityIndicatorView
            if isShowingActivityIndicatorView {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }

    private let stackView = UIStackView()
    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    // MARK: - Initialization

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        tintColor = UIColor.wkrTextColor
        selectionStyle = .none
        backgroundColor = UIColor.clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fillProportionally
        stackView.alignment = .center

        playerLabel.textColor = UIColor.wkrTextColor
        playerLabel.text = ""
        playerLabel.textAlignment = .left
        playerLabel.font = UIFont.systemFont(ofSize: 17)
        playerLabel.adjustsFontSizeToFitWidth = true

        detailLabel.text = "0"
        detailLabel.textAlignment = .right
        detailLabel.textColor = UIColor.lightGray
        detailLabel.font = UIFont.systemFont(ofSize: 20)

        stackView.addArrangedSubview(playerLabel)
        stackView.addArrangedSubview(detailLabel)

        contentView.addSubview(stackView)

        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.stopAnimating()

        contentView.addSubview(activityIndicatorView)

        let constraints = [
            stackView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 15),
            stackView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -15),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            activityIndicatorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            activityIndicatorView.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -17.5)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
