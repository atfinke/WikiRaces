//
//  MPCHostSoloCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 2/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

internal class MPCHostSoloCell: UITableViewCell {

    // MARK: - Properties

    static let reuseIdentifier = "soloCell"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.text = "Solo Race"
        textLabel?.textColor = UIColor(red: 0,
                                       green: 122.0 / 255.0,
                                       blue: 1,
                                       alpha: 1.0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
