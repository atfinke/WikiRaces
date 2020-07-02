//
//  WKRUINavigationController.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 9/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit

final public class WKRUINavigationController: UINavigationController {
    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let color: UIColor = .wkrTextColor(for: traitCollection)
        navigationBar.tintColor = color
        navigationBar.titleTextAttributes = [
            .foregroundColor: color,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }
}
