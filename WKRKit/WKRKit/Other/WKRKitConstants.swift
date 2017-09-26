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
                fatalError()
        }

        guard let version = documentsConstants["Version"] as? Int else {
            fatalError("WKRKitConstants: No Version value")
        }
        guard let quickRace = documentsConstants["QuickRace"] as? Bool else {
            fatalError("WKRKitConstants: No QuickRace value")
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

        self.pageTitleStringToReplace = pageTitleStringToReplace
        self.pageTitleCharactersToRemove = pageTitleCharactersToRemove

        self.baseURLString = baseURLString
        self.randomURLString = randomURLString
        self.whatLinksHereURLString = whatLinksHereURLString

        self.bannedURLFragments = bannedURLFragments
    }

    static public func updateConstants() {
        copyBundledPlistToDocuments()

        let publicDB = CKContainer.default().publicCloudDatabase
        let recordID = CKRecordID(recordName: "WKRKitConstantsRecord")

        publicDB.fetch(withRecordID: recordID) { record, _ in
            guard let record = record else {
                print("WKRKitConstants: Failed to get record")
                return
            }
            guard let recordVersion = record["Version"] as? Int else {
                print("WKRKitConstants: Failed to get version")
                return
            }

            guard recordVersion > WKRKitConstants.current.version else {
                print("WKRKitConstants: Have same or newer constants on device")
                return
            }

            guard let recordConstantsAsset = record["ConstantsFile"] as? CKAsset,
                let recordArticlesAsset = record["ArticlesFile"] as? CKAsset,
                let recordGetLinksScriptAsset = record["GetLinksScriptFile"] as? CKAsset else {
                    return
            }
            attemptToCopy(newConstantsFileURL: recordConstantsAsset.fileURL,
                          newArticlesFileURL: recordArticlesAsset.fileURL,
                          newGetLinksScriptFileURL: recordGetLinksScriptAsset.fileURL)
        }
    }

    static public func updatedConstants() {
        current = WKRKitConstants()
    }

    static private func attemptToCopy(newConstantsFileURL: URL,
                                      newArticlesFileURL: URL,
                                      newGetLinksScriptFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
            FileManager.default.fileExists(atPath: newArticlesFileURL.path),
            FileManager.default.fileExists(atPath: newGetLinksScriptFileURL.path) else {
                fatalError("WKRKitConstants: This shouldn't be fatal in shipping")
        }

        guard let newConstants = NSDictionary(contentsOf: newConstantsFileURL),
            let newConstantsVersion = newConstants["Version"] as? Int,
            let documentsDirectory = FileManager.default.documentsDirectory else {
                fatalError("WKRKitConstants: This shouldn't be fatal in shipping")
        }

        let documentsArticlesURL = documentsDirectory.appendingPathComponent("WKRArticlesData.plist")
        let documentsConstantsURL = documentsDirectory.appendingPathComponent("WKRKitConstants.plist")
        let documentsGetLinksScriptURL = documentsDirectory.appendingPathComponent("WKRGetLinks.js")

        var shouldReplaceExisitingConstants = true
        if FileManager.default.fileExists(atPath: documentsConstantsURL.path),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL),
            let documentsConstantsVersions = documentsConstants["Version"] as? Int {
            print("WKRKitConstants: Existing constants (v\(documentsConstantsVersions)) @ \(documentsConstantsURL.path)")
            if newConstantsVersion <= documentsConstantsVersions {
                shouldReplaceExisitingConstants = false
            }
        }

        print("WKRKitConstants: Replacing existing constants with bundled: \(shouldReplaceExisitingConstants)")
        if shouldReplaceExisitingConstants {
            do {
                try? FileManager.default.removeItem(at: documentsArticlesURL)
                try FileManager.default.copyItem(at: newArticlesFileURL, to: documentsArticlesURL)
                
                try? FileManager.default.removeItem(at: documentsGetLinksScriptURL)
                try FileManager.default.copyItem(at: newGetLinksScriptFileURL, to: documentsGetLinksScriptURL)

                try? FileManager.default.removeItem(at: documentsConstantsURL)
                try FileManager.default.copyItem(at: newConstantsFileURL, to: documentsConstantsURL)
            } catch {
                fatalError("WKRKitConstants: Something really bad happened")
            }
        }
        updatedConstants()
    }

    static private func copyBundledPlistToDocuments() {
        guard let bundle = Bundle(identifier: "com.andrewfinke.WKRKit"),
            let bundledPlistURL = bundle.url(forResource: "WKRKitConstants", withExtension: "plist"),
            let bundledArticlesURL = bundle.url(forResource: "WKRArticlesData", withExtension: "plist"),
            let bundledGetLinksScriptURL = bundle.url(forResource: "WKRGetLinks", withExtension: "js") else {
                fatalError()
        }

        attemptToCopy(newConstantsFileURL: bundledPlistURL,
                      newArticlesFileURL: bundledArticlesURL,
                      newGetLinksScriptFileURL: bundledGetLinksScriptURL)
    }

    static internal func finalArticles() -> [String] {
        //swiftlint:disable:next line_length
        guard let documentsArticlesURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRArticlesData.plist"),
            let arrayFromURL = NSArray(contentsOf: documentsArticlesURL),
            let array = arrayFromURL as? [String] else {
                fatalError()
        }
        return array
    }

    static internal func getLinksScript() -> String {
        //swiftlint:disable:next line_length
        guard let documentsGetLinksScriptURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRGetLinks.js"),
            let source = try? String(contentsOf: documentsGetLinksScriptURL) else {
                fatalError()
        }
        return source
    }

}

extension FileManager {
    var documentsDirectory: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
