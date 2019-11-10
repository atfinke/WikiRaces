//
//  WKRWindow.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class WKRWindow: UIWindow {
    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundColor = .wkrBackgroundColor(for: traitCollection)
    }
}
