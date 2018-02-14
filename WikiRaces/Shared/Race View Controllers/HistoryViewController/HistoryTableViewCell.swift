//
//  HistoryTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

internal class HistoryTableViewCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "reuseIdentifier"
    static let finalReuseIdentifier = "finalCell"

    private let activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    var isShowingActivityIndicatorView: Bool = false {
        didSet {
            detailTextLabel?.isHidden = isShowingActivityIndicatorView
            if isShowingActivityIndicatorView {
                activityIndicatorView.startAnimating()
            } else {
                activityIndicatorView.stopAnimating()
            }
        }
    }

    // MARK: - View Life Cycle

    override func awakeFromNib() {
        super.awakeFromNib()

        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.stopAnimating()
        addSubview(activityIndicatorView)

        let constraints = [
            activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor),
            activityIndicatorView.rightAnchor.constraint(equalTo: rightAnchor, constant: -12)
        ]
        NSLayoutConstraint.activate(constraints)
    }
}
