//
//  WKRUIButton.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIButton: UIButton {

    // MARK: - Properties

    public var style: WKRUIButtonStyle {
        didSet {
            title = attributedTitle(for: .normal)?.string ?? ""
        }
    }

    public var title: String = "" {
        didSet {
            let font = style.font
            let spacing = style.textSpacing
            let uppercasedTitle = title.uppercased()

            let normalString =      NSAttributedString(string: uppercasedTitle,
                                                       spacing: spacing,
                                                       font: font,
                                                       textColor: UIColor.wkrTextColor)

            let highlightedString = NSAttributedString(string: uppercasedTitle,
                                                       spacing: spacing,
                                                       font: font,
                                                       textColor: UIColor.wkrLightTextColor)

            setAttributedTitle(normalString, for: .normal)
            setAttributedTitle(highlightedString, for: .highlighted)
        }
    }

    // MARK: - Initialization

    public init(style: WKRUIButtonStyle = .normal) {
        self.style = style
        super.init(frame: .zero)

        layer.cornerRadius = 5
        layer.borderWidth = 1.3
        layer.borderColor = UIColor.wkrTextColor.cgColor
        backgroundColor = UIColor.clear

        setTitleColor(UIColor.green, for: .highlighted)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
