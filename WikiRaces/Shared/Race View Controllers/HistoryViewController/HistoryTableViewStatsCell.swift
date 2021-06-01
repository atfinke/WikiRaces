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
            textLabel?.text = stat?.key
            detailTextLabel?.text = stat?.value
        }
    }

    // MARK: - Initialization -

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        textLabel?.font = UIFont.tableViewCellTitle()
        detailTextLabel?.font = UIFont.tableViewCellDetail()
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
        textLabel?.textColor = textColor
        detailTextLabel?.textColor = .wkrSubtitleTextColor(for: traitCollection)
    }

}
