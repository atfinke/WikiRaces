//
//  WKRUIButtonStyle.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public enum WKRUIButtonStyle {
    case small
    case normal
    case large

    var font: UIFont {
        switch self {
        case .small:  return UIFont.systemFont(ofSize: 12.0, weight: .semibold)
        case .normal: return UIFont.systemFont(ofSize: 16.0, weight: .semibold)
        case .large: return UIFont.systemFont(ofSize: 20.0, weight: .semibold)
        }
    }

    var textSpacing: Double {
        switch self {
        case .small:  return 1.5
        case .normal, .large: return 4.44
        }
    }
}
