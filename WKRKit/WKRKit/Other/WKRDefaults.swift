//
//  WKRDefaults.swift
//  WKRKit
//
//  Created by Andrew Finke on 7/18/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

struct WKRDefaults {
    private static let fastlaneKey = "FASTLANE_SNAPSHOT"
    static var isFastlaneSnapshotInstance: Bool {
        get {
            return UserDefaults.standard.bool(forKey: fastlaneKey)
        }
    }
}
