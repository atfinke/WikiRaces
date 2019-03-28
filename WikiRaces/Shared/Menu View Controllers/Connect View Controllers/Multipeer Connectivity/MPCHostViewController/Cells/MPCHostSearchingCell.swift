//
//  MPCHostSearchingCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 12/26/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

internal class MPCHostSearchingCell: UITableViewCell {

    // MARK: - Properties

    private var dots: Int = 3
    private var timer: Timer?

    static let reuseIdentifier = "searchingCell"

    // MARK: - Initialization

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        isUserInteractionEnabled = false
        backgroundColor = UIColor.wkrBackgroundColor
        textLabel?.textColor = UIColor(red: 184.0 / 255.0,
                                       green: 184.0 / 255.0,
                                       blue: 184.0 / 255.0,
                                       alpha: 1.0)

        updateText()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { [weak self] _ in
            self?.updateText()
        })
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    // MARK: - Helpers

    func updateText() {
        dots += 1
        if dots >= 4 {
            dots = 0
        }
        textLabel?.text = "Searching" + (0..<self.dots).map({ _ in "." })
    }

}
