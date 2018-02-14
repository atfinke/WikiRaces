//
//  WKRConstants.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import Foundation

public class WKRKitConstants {

    public let version: Int
    public static var current = WKRKitConstants()

    internal let quickRace: Bool
    public let connectionTestTimeout: Double

    internal let pageTitleStringToReplace: String
    internal let pageTitleCharactersToRemove: Int

    internal let baseURLString: String
    internal let randomURLString: String
    internal let whatLinksHereURLString: String

    internal let bannedURLFragments: [String]

    init() {
        //swiftlint:disable:next line_length
        guard let documentsConstantsURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRKitConstants.plist"),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL) as? [String:Any] else {
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
        guard let baseURLString = documentsConstants["BaseURLString"] as? String else {
            fatalError("WKRKitConstants: No BaseURLString value")
        }
        guard let randomURLString = documentsConstants["RandomURLString"] as? String else {
            fatalError("WKRKitConstants: No RandomURLString value")
        }
        guard let whatLinksHereURLString = documentsConstants["WhatLinksHereURLString"] as? String else {
            fatalError("WKRKitConstants: No WhatLinksHereURLString value")
        }
        guard let bannedURLFragments = documentsConstants["BannedURLFragments"] as? [String] else {
            fatalError("WKRKitConstants: No BannedURLFragments value")
        }

        self.version = version
        self.quickRace = quickRace
        self.connectionTestTimeout = connectionTestTimeout

        self.pageTitleStringToReplace = pageTitleStringToReplace
        self.pageTitleCharactersToRemove = pageTitleCharactersToRemove

        self.baseURLString = baseURLString
        self.randomURLString = randomURLString
        self.whatLinksHereURLString = whatLinksHereURLString

        self.bannedURLFragments = bannedURLFragments
    }

    @available(*, deprecated, message: "Only for debugging")
    static public func removeConstants() {
        let fileManager = FileManager.default
        let folderPath = FileManager.default.documentsDirectory!.path
        guard let filePaths = try? fileManager.contentsOfDirectory(atPath: folderPath) else {
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

    @available(*, deprecated, message: "Only for debugging")
    static public func updateConstantsForTestingCharacterClipping() {
        copyBundledResourcesToDocuments(constantsFileName: "WKRKitConstants-TESTING_ONLY")
    }

    static public func updateConstants() {
        copyBundledResourcesToDocuments()

        guard ProcessInfo.processInfo.environment["Cloud_Disabled"] != "true" else {
            return
        }

        let publicDB = CKContainer.default().publicCloudDatabase
        let recordID = CKRecordID(recordName: "WKRKitConstantsRecord")

        publicDB.fetch(withRecordID: recordID) { record, _ in
            guard let record = record else {
                return
            }

            guard let recordConstantsAsset = record["ConstantsFile"] as? CKAsset,
                let recordArticlesAsset = record["ArticlesFile"] as? CKAsset,
                let recordGetLinksScriptAsset = record["GetLinksScriptFile"] as? CKAsset else {
                    return
            }

            copyIfNewer(newConstantsFileURL: recordConstantsAsset.fileURL,
                        newArticlesFileURL: recordArticlesAsset.fileURL,
                        newGetLinksScriptFileURL: recordGetLinksScriptAsset.fileURL)
        }
    }

    static private func copyIfNewer(newConstantsFileURL: URL,
                                    newArticlesFileURL: URL,
                                    newGetLinksScriptFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
            FileManager.default.fileExists(atPath: newArticlesFileURL.path),
            FileManager.default.fileExists(atPath: newGetLinksScriptFileURL.path) else {
                return
        }

        guard let newConstants = NSDictionary(contentsOf: newConstantsFileURL),
            let newConstantsVersion = newConstants["Version"] as? Int,
            let documentsDirectory = FileManager.default.documentsDirectory else {
                return
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

        current = WKRKitConstants()
    }

    static private func copyBundledResourcesToDocuments(constantsFileName: String = "WKRKitConstants") {
        guard let bundle = Bundle(identifier: "com.andrewfinke.WKRKit"),
            let bundledPlistURL = bundle.url(forResource: constantsFileName, withExtension: "plist"),
            let bundledArticlesURL = bundle.url(forResource: "WKRArticlesData", withExtension: "plist"),
            let bundledGetLinksScriptURL = bundle.url(forResource: "WKRGetLinks", withExtension: "js") else {
                fatalError("Failed to load bundled constants")
        }

        copyIfNewer(newConstantsFileURL: bundledPlistURL,
                    newArticlesFileURL: bundledArticlesURL,
                    newGetLinksScriptFileURL: bundledGetLinksScriptURL)
    }

    internal func finalArticles() -> [String] {
        //swiftlint:disable:next line_length
        guard let documentsArticlesURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRArticlesData.plist"),
            let arrayFromURL = NSArray(contentsOf: documentsArticlesURL),
            let array = arrayFromURL as? [String] else {
                fatalError("Failed to load articles plist")
        }
        return array
    }

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
