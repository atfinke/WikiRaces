//
//  WKRUIButtonStyle.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

public enum WKRButtonStyle {
    case small
    case normal

    var font: UIFont {
        switch self {
        case .small:  return UIFont.systemFont(ofSize: 12.0, weight: .medium)
        case .normal: return UIFont.systemFont(ofSize: 16.0, weight: .medium)
        }
    }

    var textSpacing: Double {
        switch self {
        case .small:  return 1.5
        case .normal: return 4.44
        }
    }
}
