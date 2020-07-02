//
//  OSLog+WikiRaces.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/30/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation
import os.log

extension OSLog {

    // MARK: - Types -

    private enum CustomCategory: String {
        case store, gameKit, nearby, matchSupport, raceLiveDatabase
    }

    private static let subsystem: String = {
        guard let identifier = Bundle.main.bundleIdentifier else { fatalError() }
        return identifier
    }()

    static let store = OSLog(subsystem: subsystem, category: CustomCategory.store.rawValue)
    static let gameKit = OSLog(subsystem: subsystem, category: CustomCategory.gameKit.rawValue)
    static let nearby = OSLog(subsystem: subsystem, category: CustomCategory.nearby.rawValue)
    static let matchSupport = OSLog(subsystem: subsystem, category: CustomCategory.matchSupport.rawValue)
    static let raceLiveDatabase = OSLog(subsystem: subsystem, category: CustomCategory.raceLiveDatabase.rawValue)
    
}
