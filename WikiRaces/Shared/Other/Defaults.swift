//
//  Defaults.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import Foundation

struct Defaults {

    private static let defaults = UserDefaults.standard

    private static let promptedGlobalRacesPopularityKey = "PromptedGlobalRacesPopularity"
    static var promptedGlobalRacesPopularity: Bool {
        get {
            return defaults.bool(forKey: promptedGlobalRacesPopularityKey)
        }
        set {
            defaults.set(newValue, forKey: promptedGlobalRacesPopularityKey)
        }
    }

    private static let fastlaneKey = "FASTLANE_SNAPSHOT"
    static var isFastlaneSnapshotInstance: Bool {
        get {
            return defaults.bool(forKey: fastlaneKey)
        }
    }

    private static let isAutoInviteOnKey = "isAutoInviteOnKey"
    static var isAutoInviteOn: Bool {
        get {
            return defaults.bool(forKey: isAutoInviteOnKey)
        }
        set {
            defaults.set(newValue, forKey: isAutoInviteOnKey)
        }
    }

    private static let promptedAutoInviteKey = "PromptedAutoInviteKey"
    static var promptedAutoInvite: Bool {
        get {
            return defaults.bool(forKey: promptedAutoInviteKey)
        }
        set {
            defaults.set(newValue, forKey: promptedAutoInviteKey)
        }
    }

    private static let shouldPromptForRatingKey = "ShouldPromptForRating"
    static var shouldPromptForRating: Bool {
        get {
            return defaults.bool(forKey: shouldPromptForRatingKey)
        }
        set {
            defaults.setValue(newValue, forKey: shouldPromptForRatingKey)
        }
    }

    private static let shouldAutoSaveResultImageKey = "force_save_result_image"
    static var shouldAutoSaveResultImage: Bool {
        get {
            return defaults.bool(forKey: shouldAutoSaveResultImageKey)
        }
        set {
            defaults.setValue(newValue, forKey: shouldAutoSaveResultImageKey)
        }
    }

    private static let promptedSoloRacesStatsKey = "PromptedSoloRacesStatsKey"
    static var promptedSoloRacesStats: Bool {
        get {
            return defaults.bool(forKey: promptedSoloRacesStatsKey)
        }
        set {
            defaults.set(newValue, forKey: promptedSoloRacesStatsKey)
        }
    }

}
