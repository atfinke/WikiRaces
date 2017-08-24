//
//  FooterButtonTableViewCell.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

class FooterButtonTableViewCell: UITableViewCell {

    // MARK: - Properties

    let button = WKRUIButton(style: .small)

    // MARK: - Initialization

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let thinLine = UIView()
        thinLine.alpha = 0.25
        thinLine.backgroundColor = UIColor.wkrTextColor
        thinLine.translatesAutoresizingMaskIntoConstraints = false
        addSubview(thinLine)

        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)

        let constraints = [
            thinLine.topAnchor.constraint(equalTo: topAnchor),
            thinLine.heightAnchor.constraint(equalToConstant: 1.0),
            thinLine.leftAnchor.constraint(equalTo: leftAnchor),
            thinLine.rightAnchor.constraint(equalTo: rightAnchor),

            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 140),
            button.heightAnchor.constraint(equalToConstant: 25)
        ]
        NSLayoutConstraint.activate(constraints)

        backgroundColor = UIColor.clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
