//
//  WKRUIBarButtonItem.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 5/6/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

public class WKRUIBarButtonItem: UIBarButtonItem {
    public convenience init(systemName: String, weight: UIImage.SymbolWeight = .medium, target: Any?, action: Selector?) {
        let config = UIImage.SymbolConfiguration(weight: weight)
        guard let image = UIImage(systemName: systemName, withConfiguration: config) else { fatalError() }
        self.init(image: image, style: .plain, target: target, action: action)
    }
}
