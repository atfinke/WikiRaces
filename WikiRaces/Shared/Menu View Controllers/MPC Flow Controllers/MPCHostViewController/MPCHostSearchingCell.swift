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

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        updateText()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
            self.updateText()
        })
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
