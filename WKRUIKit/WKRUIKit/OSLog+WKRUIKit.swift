//
//  OSLog+WKRUIKit.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 7/2/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import os.log

extension OSLog {

    // MARK: - Types -

    private enum CustomCategory: String {
        case imageManager
    }

    private static let subsystem: String = {
        guard let identifier = Bundle.main.bundleIdentifier else { fatalError() }
        return identifier
    }()

    static let imageManager = OSLog(subsystem: subsystem, category: CustomCategory.imageManager.rawValue)

}
