//
//  MenuTile.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

internal class MenuTile: UIControl {

    // MARK: - Properties

    /// Used for displaying the stat number (i.e. 3.33333 to 3.33)
    static private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "" // 1,000 -> 1000
        return formatter
    }()

    static private let fractionalNumberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 1
        return formatter
    }()

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    var stat: StatsHelper.Stat?
    var title: String? {
        set {
            guard let text = newValue else {
                titleLabel.text = nil
                return
            }
            titleLabel.attributedText = NSAttributedString(string: text,
                                                           spacing: 3.0,
                                                           font: titleLabel.font,
                                                           textColor: UIColor.wkrTextColor)
        }
        get {
            return titleLabel.attributedText?.string
        }
    }

    var value: Double? {
        set {
            guard let value = newValue  else {
                valueLabel.text = nil
                return
            }
            var formattedValue = MenuTile.numberFormatter.string(from: NSNumber(value: value))
            if let stat = stat, stat == .average {
                formattedValue = MenuTile.fractionalNumberFormatter.string(from: NSNumber(value: value))
            }
            valueLabel.text = formattedValue
        }
        get {
            return nil
        }
    }

    /// Updates the font sizes based on width changes
    override var bounds: CGRect {
        didSet {
            if bounds.width > 200 {
                titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
                valueLabel.font = UIFont.systemFont(ofSize: 46)
            } else if bounds.width > 100 {
                titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
                valueLabel.font = UIFont.systemFont(ofSize: 38)
            } else {
                titleLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
                valueLabel.font = UIFont.systemFont(ofSize: 30)
            }
        }
    }

    // MARK: - Initialization

    /// Init with the tile's title
    ///
    /// - Parameter title: The title
    init(title: String) {
        super.init(frame: .zero)

        self.title = title
        self.value = 0

        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.textColor = UIColor.wkrTextColor
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)

        let constraints = [
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 25),
            titleLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            titleLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -10),
            titleLabel.heightAnchor.constraint(equalToConstant: 50),

            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            valueLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: 15),
            valueLabel.rightAnchor.constraint(equalTo: rightAnchor),
            valueLabel.heightAnchor.constraint(equalToConstant: 80)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
