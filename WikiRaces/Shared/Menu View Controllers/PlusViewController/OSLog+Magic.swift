//
//  OSLog+Magic.swift
//  Magic
//
//  Created by Andrew Finke on 9/26/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation
import os.log

extension OSLog {

    // MARK: - Types -

    private enum CustomCategory: String {
        case store
    }

    // MARK: - Properties -

    private static let subsystem: String = {
        guard let identifier = Bundle.main.bundleIdentifier else { fatalError() }
        return identifier
    }()

    static let store = OSLog(subsystem: subsystem, category: CustomCategory.store.rawValue)
}
