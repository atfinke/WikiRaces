//
//  WKRUIButton.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIButton: UIButton {

    // MARK: - Properties -

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
                                                       font: font)

            let highlightedString = NSAttributedString(string: uppercasedTitle,
                                                       spacing: spacing,
                                                       font: font)

            setAttributedTitle(normalString, for: .normal)
            setAttributedTitle(highlightedString, for: .highlighted)
        }
    }

    // MARK: - Initialization -

    public init(style: WKRUIButtonStyle = .normal) {
        self.style = style
        super.init(frame: .zero)

        layer.cornerRadius = 5
        layer.borderWidth = 1.7
        backgroundColor = .clear

        setTitleColor(.green, for: .highlighted)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    public override func layoutSubviews() {
        super.layoutSubviews()
        let textColor = UIColor.wkrTextColor(for: traitCollection)
        let subtitleTextColor = UIColor.wkrSubtitleTextColor(for: traitCollection)

        layer.borderColor = textColor.cgColor
        setTitleColor(textColor, for: .normal)
        setTitleColor(subtitleTextColor, for: .highlighted)
    }

}
