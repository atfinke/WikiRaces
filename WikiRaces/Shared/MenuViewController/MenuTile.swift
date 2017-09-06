//
//  MenuTile.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

class MenuTile: UIView {

    // MARK: - Properties

    static private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    // MARK: - Initialization

    init(title: String, value: Double) {
        super.init(frame: .zero)

        titleLabel.attributedText = NSAttributedString(string: title,
                                                       spacing: 3.0,
                                                       font: titleLabelFont(),
                                                       textColor: UIColor.wkrTextColor)

        //titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        valueLabel.text = MenuTile.numberFormatter.string(from: NSNumber(value: value))
        //valueLabel.textAlignment = .center
        valueLabel.textColor = UIColor.wkrTextColor
        valueLabel.font = valueLabelFont()
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

    // MARK: - Fonts

    func titleLabelFont() -> UIFont {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIFont.boldSystemFont(ofSize: 18)
        } else if UIScreen.main.bounds.height > 575 {
            return UIFont.boldSystemFont(ofSize: 14)
        } else {
            return UIFont.boldSystemFont(ofSize: 12)
        }
    }

    func valueLabelFont() -> UIFont {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return UIFont.systemFont(ofSize: 46)
        } else if UIScreen.main.bounds.height > 575 {
            return UIFont.systemFont(ofSize: 38)
        } else {
            return UIFont.systemFont(ofSize: 28)
        }
    }

}
