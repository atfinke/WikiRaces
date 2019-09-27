//
//  HistoryTableViewStatsCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/28/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

internal class HistoryTableViewStatsCell: UITableViewCell {

    // MARK: - Properties

    var stat: (key: String, value: String)? {
        didSet {
            textLabel?.text = stat?.key
            detailTextLabel?.text = stat?.value
        }
    }

    static let reuseIdentifier = "statsReuseIdentifier"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)

        detailTextLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        isUserInteractionEnabled = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        textLabel?.textColor = textColor
        detailTextLabel?.textColor = textColor
    }

}
