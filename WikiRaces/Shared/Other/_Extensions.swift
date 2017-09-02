//
//  _Extensions.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import WKRKit

extension IndexPath {
    init(row: Int) {
        self.init(row: row, section: 0)
    }
}

extension UIView {
    static func animate(withDuration duration: Double,
                        delay: Double,
                        animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)? = nil) {
        
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: .beginFromCurrentState,
                       animations: animations,
                       completion: completion)
    }
}

extension UINavigationController {
    var rootViewController: UIViewController? {
        return viewControllers.first
    }
}

func wikiDebugLog(_ object: Any? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    _debugLog(object, file: file, function: function, line: line)
}
