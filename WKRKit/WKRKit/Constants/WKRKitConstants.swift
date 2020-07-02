//
//  WKRKitConstants.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import os.log

public struct WKRKitConstants {

    // MARK: - Properties

    public let version: Int
    public static var current = WKRKitConstants()

    internal let isQuickRaceMode: Bool
    public let connectionTestTimeout: Double

    internal let pageTitleStringToReplace: String
    internal let pageTitleCharactersToRemove: Int
    internal let pageTitleMaxRandomLength: Int

    internal let baseURLString: String
    internal let randomURLString: String
    internal let whatLinksHereURLString: String

    internal let bonusPointReward: Int
    internal let bonusPointsInterval: Double

    internal let maxFoundPagePlayers: Int
    internal let votingArticlesCount: Int

    internal let bannedURLFragments: [String]

    public let maxGlobalRacePlayers: Int
    public let maxLocalRacePlayers: Int

    public let manageGameCenterLink: URL
    public let raceCodeRecordMinReuseTimeSinceLastUpdate: Int

    // MARK: - Initalization

    init() {
        os_log("%{public}s", log: .constants, type: .info, #function)

        guard let documentsConstantsURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRKitConstants.plist"),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL) as? [String: Any] else {
                fatalError("Failed to load constants")
        }

        guard let version = documentsConstants["Version"] as? Int else {
            fatalError("WKRKitConstants: No Version value")
        }
        guard let quickRace = documentsConstants["QuickRace"] as? Bool else {
            fatalError("WKRKitConstants: No QuickRace value")
        }
        guard let connectionTestTimeout = documentsConstants["ConnectionTestTimeout"] as? Double else {
            fatalError("WKRKitConstants: No ConnectionTestTimeout value")
        }
        guard let pageTitleStringToReplace = documentsConstants["PageTitleStringToReplace"] as? String else {
            fatalError("WKRKitConstants: No PageTitleStringToReplace value")
        }
        guard let pageTitleCharactersToRemove = documentsConstants["PageTitleCharactersToRemove"] as? Int else {
            fatalError("WKRKitConstants: No PageTitleCharactersToRemove value")
        }
        guard let pageTitleMaxRandomLength = documentsConstants["PageTitleMaxRandomLength"] as? Int else {
            fatalError("WKRKitConstants: No PageTitleMaxRandomLength value")
        }
        guard let baseURLString = documentsConstants["BaseURLString"] as? String else {
            fatalError("WKRKitConstants: No BaseURLString value")
        }
        guard let randomURLString = documentsConstants["RandomURLString"] as? String else {
            fatalError("WKRKitConstants: No RandomURLString value")
        }
        guard let whatLinksHereURLString = documentsConstants["WhatLinksHereURLString"] as? String else {
            fatalError("WKRKitConstants: No WhatLinksHereURLString value")
        }
        guard let bonusPointReward = documentsConstants["BonusPointReward"] as? Int else {
            fatalError("WKRKitConstants: No BonusPointReward value")
        }
        guard let bonusPointsInterval = documentsConstants["BonusPointsInterval"] as? Double else {
            fatalError("WKRKitConstants: No BonusPointsInterval value")
        }
        guard let maxFoundPagePlayers = documentsConstants["MaxFoundPagePlayers"] as? Int else {
            fatalError("WKRKitConstants: No MaxFoundPagePlayers value")
        }
        guard let votingArticlesCount = documentsConstants["VotingArticlesCount"] as? Int else {
            fatalError("WKRKitConstants: No VotingArticlesCount value")
        }
        guard let bannedURLFragments = documentsConstants["BannedURLFragments"] as? [String] else {
            fatalError("WKRKitConstants: No BannedURLFragments value")
        }
        guard let maxGlobalRacePlayers = documentsConstants["MaxGlobalRacePlayers"] as? Int else {
            fatalError("WKRKitConstants: No MaxGlobalRacePlayers value")
        }
        guard let maxLocalRacePlayers = documentsConstants["MaxLocalRacePlayers"] as? Int else {
            fatalError("WKRKitConstants: No MaxLocalRacePlayers value")
        }

        guard let manageGameCenterLinkString = documentsConstants["ManageGameCenterLink"] as? String,
              let manageGameCenterLink = URL(string: manageGameCenterLinkString) else {
            fatalError("WKRKitConstants: No ManageGameCenterLink value")
        }
        guard let raceCodeRecordMinReuseTimeSinceLastUpdate = documentsConstants["RaceCodeRecordMinReuseTimeSinceLastUpdate"] as? Int else {
            fatalError("WKRKitConstants: No RaceCodeRecordMinReuseTimeSinceLastUpdate value")
        }

        self.version = version
        self.isQuickRaceMode = quickRace
        self.connectionTestTimeout = connectionTestTimeout

        self.pageTitleStringToReplace = pageTitleStringToReplace
        self.pageTitleCharactersToRemove = pageTitleCharactersToRemove
        self.pageTitleMaxRandomLength = pageTitleMaxRandomLength

        self.baseURLString = baseURLString
        self.randomURLString = randomURLString
        self.whatLinksHereURLString = whatLinksHereURLString

        self.bonusPointReward = bonusPointReward
        self.bonusPointsInterval = bonusPointsInterval

        self.maxFoundPagePlayers = maxFoundPagePlayers
        self.votingArticlesCount = votingArticlesCount

        self.bannedURLFragments = bannedURLFragments
        self.maxGlobalRacePlayers = maxGlobalRacePlayers
        self.maxLocalRacePlayers = maxLocalRacePlayers

        self.manageGameCenterLink = manageGameCenterLink
        self.raceCodeRecordMinReuseTimeSinceLastUpdate = raceCodeRecordMinReuseTimeSinceLastUpdate
    }

    // MARK: - Helpers

    @available(*, deprecated, message: "Only for testing")
    static public func removeConstants() {
        os_log("%{public}s", log: .constants, type: .info, #function)
        let fileManager = FileManager.default

        guard let folderPath = fileManager.documentsDirectory?.path,
            let filePaths = try? fileManager.contentsOfDirectory(atPath: folderPath) else {
                fatalError()
        }
        for filePath in filePaths {
            do {
                try fileManager.removeItem(atPath: folderPath + "/" + filePath)
            } catch {
                print(error)
            }
        }
    }

    @available(*, deprecated, message: "Only for testing")
    static public func updateConstantsForTestingCharacterClipping() {
        os_log("%{public}s", log: .constants, type: .info, #function)
        copyBundledResourcesToDocuments(constantsFileName: "WKRKitConstants-TESTING_ONLY")
    }

    static public func updateConstants() {
        os_log("%{public}s", log: .constants, type: .info, #function)
        copyBundledResourcesToDocuments()

        guard ProcessInfo.processInfo.environment["Cloud_Disabled"] != "true" else {
            return
        }

        let publicDB = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "WKRKitConstantsRecord")

        publicDB.fetch(withRecordID: recordID) { record, _ in
            guard let record = record else {
                os_log("%{public}s: no record", log: .constants, type: .error, #function)
                return
            }

            guard let recordConstantsAssetURL = (record["ConstantsFile"] as? CKAsset)?.fileURL,
                let recordArticlesAssetURL = (record["ArticlesFile"] as? CKAsset)?.fileURL,
                let recordGetLinksScriptAssetURL = (record["GetLinksScriptFile"] as? CKAsset)?.fileURL else {
                    os_log("%{public}s: invalid record assets", log: .constants, type: .error, #function)
                    return
            }

            DispatchQueue.main.async {
                copyIfNewer(newConstantsFileURL: recordConstantsAssetURL,
                            newArticlesFileURL: recordArticlesAssetURL,
                            newGetLinksScriptFileURL: recordGetLinksScriptAssetURL)
            }
        }
    }

    static private func copyIfNewer(newConstantsFileURL: URL,
                                    newArticlesFileURL: URL,
                                    newGetLinksScriptFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
            FileManager.default.fileExists(atPath: newArticlesFileURL.path),
            FileManager.default.fileExists(atPath: newGetLinksScriptFileURL.path) else {
                os_log("%{public}s: files don't exist", log: .constants, type: .error, #function)
                return
        }

        guard let newConstants = NSDictionary(contentsOf: newConstantsFileURL),
            let newConstantsVersion = newConstants["Version"] as? Int,
            let documentsDirectory = FileManager.default.documentsDirectory else {
                os_log("%{public}s: version doesn't exist", log: .constants, type: .error, #function)
                return
        }

        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            try? FileManager.default.createDirectory(at: documentsDirectory,
                                                     withIntermediateDirectories: false,
                                                     attributes: nil)
        }

        let documentsArticlesURL = documentsDirectory.appendingPathComponent("WKRArticlesData.plist")
        let documentsConstantsURL = documentsDirectory.appendingPathComponent("WKRKitConstants.plist")
        let documentsGetLinksScriptURL = documentsDirectory.appendingPathComponent("WKRGetLinks.js")

        var shouldReplaceExisitingConstants = true
        if FileManager.default.fileExists(atPath: documentsConstantsURL.path),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL),
            let documentsConstantsVersions = documentsConstants["Version"] as? Int {

            if newConstantsVersion <= documentsConstantsVersions {
                shouldReplaceExisitingConstants = false
                os_log("%{public}s: don't replace: new: %{public}ld, existing: %{public}ld", log: .constants, type: .info, #function, newConstantsVersion, documentsConstantsVersions)
            } else {
                os_log("%{public}s: replace: new: %{public}ld, existing: %{public}ld", log: .constants, type: .info, #function, newConstantsVersion, documentsConstantsVersions)
            }
        }

        if shouldReplaceExisitingConstants {
            do {
                try? FileManager.default.removeItem(at: documentsArticlesURL)
                try FileManager.default.copyItem(at: newArticlesFileURL, to: documentsArticlesURL)

                try? FileManager.default.removeItem(at: documentsGetLinksScriptURL)
                try FileManager.default.copyItem(at: newGetLinksScriptFileURL, to: documentsGetLinksScriptURL)

                try? FileManager.default.removeItem(at: documentsConstantsURL)
                try FileManager.default.copyItem(at: newConstantsFileURL, to: documentsConstantsURL)
            } catch {
                print(error)
            }
        }

        let newCurrentConstants = WKRKitConstants()
        WKRKitConstants.current = newCurrentConstants
    }

    static private func copyBundledResourcesToDocuments(constantsFileName: String = "WKRKitConstants") {
        os_log("%{public}s", log: .constants, type: .error, #function)

        guard Thread.isMainThread,
            let bundle = Bundle(identifier: "com.andrewfinke.WKRKit"),
            let bundledPlistURL = bundle.url(forResource: constantsFileName, withExtension: "plist"),
            let bundledArticlesURL = bundle.url(forResource: "WKRArticlesData", withExtension: "plist"),
            let bundledGetLinksScriptURL = bundle.url(forResource: "WKRGetLinks", withExtension: "js") else {
                fatalError("Failed to load bundled constants")
        }

        copyIfNewer(newConstantsFileURL: bundledPlistURL,
                    newArticlesFileURL: bundledArticlesURL,
                    newGetLinksScriptFileURL: bundledGetLinksScriptURL)
    }

    lazy public private(set) var finalArticles: [String] = {
        guard let documentsArticlesURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRArticlesData.plist"),
            let arrayFromURL = NSArray(contentsOf: documentsArticlesURL),
            let array = arrayFromURL as? [String] else {
                fatalError("Failed to load articles plist")
        }
        return array
    }()

    internal func getLinksScript() -> String {
        guard let documentsScriptURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRGetLinks.js"),
            let source = try? String(contentsOf: documentsScriptURL) else {
                fatalError("Failed to load get links script")
        }
        return source
    }

}

extension FileManager {
    var documentsDirectory: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
