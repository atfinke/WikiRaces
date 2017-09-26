//
//  WKRUIConstants.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import Foundation

public struct WKRUIConstants {

    // MARK: Not Updated OTA

    static let webViewAnimateInDuration   = 0.25
    static let webViewAnimateOutDuration  = 0.25

    static let progessViewAnimateOutDelay     = 0.85
    static let progessViewAnimateOutDuration  = 0.4

    static let alertHeight: CGFloat     = 50.0
    static let alertAnimateInDuration   = 0.25
    static let alertAnimateOutDuration  = 0.25
    public static let alertDefaultDuration = 5.0

    // MARK: Updated OTA

    public let version: Int
    public static var current = WKRUIConstants()

    init() {
        //swiftlint:disable:next line_length
        guard let documentsConstantsURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRUIConstants.plist"),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL) as? [String:Any] else {
                fatalError()
        }

        guard let version = documentsConstants["Version"] as? Int else {
            fatalError("WKRUIConstants: No Version value")
        }

        self.version = version
    }

    static public func updateConstants() {
        copyBundledResourcesToDocuments()

        let publicDB = CKContainer.default().publicCloudDatabase
        let recordID = CKRecordID(recordName: "WKRUIConstantsRecord")

        publicDB.fetch(withRecordID: recordID) { record, _ in
            guard let record = record else {
                print("WKRUIConstants Cloud: Failed to get record")
                return
            }
            guard let recordVersion = record["Version"] as? Int else {
                print("WKRUIConstants Cloud: Failed to get version")
                return
            }

            guard recordVersion > WKRUIConstants.current.version else {
                print("WKRUIConstants Cloud: Have same or newer constants on device")
                return
            }

            guard let recordConstantsAsset = record["ConstantsFile"] as? CKAsset,
                let recordPreHideScriptAsset = record["PreHideScriptFile"] as? CKAsset,
                let recordPostHideScriptAsset = record["PostHideScriptFile"] as? CKAsset else {
                    print("WKRKitConstants Cloud: No assets")
                    return
            }

            print("WKRKitConstants Cloud: Attempt to copy")

            copyIfNewer(newConstantsFileURL: recordConstantsAsset.fileURL,
                          newPreHideScriptFileURL: recordPreHideScriptAsset.fileURL,
                          newPostHideScriptFileURL: recordPostHideScriptAsset.fileURL)
        }
    }

    static private func copyIfNewer(newConstantsFileURL: URL,
                                      newPreHideScriptFileURL: URL,
                                      newPostHideScriptFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
            FileManager.default.fileExists(atPath: newPreHideScriptFileURL.path),
            FileManager.default.fileExists(atPath: newPostHideScriptFileURL.path) else {
                fatalError("WKRUIConstants: This shouldn't be fatal in shipping")
        }

        guard let newConstants = NSDictionary(contentsOf: newConstantsFileURL),
            let newConstantsVersion = newConstants["Version"] as? Int,
            let documentsDirectory = FileManager.default.documentsDirectory else {
                fatalError("WKRUIConstants: This shouldn't be fatal in shipping")
        }

        let documentsConstantsURL = documentsDirectory.appendingPathComponent("WKRUIConstants.plist")
        let documentsPreHideScriptURL = documentsDirectory.appendingPathComponent("WKRPreHideScript.js")
        let documentsPostHideScriptURL = documentsDirectory.appendingPathComponent("WKRPostHideScript.js")

        var shouldReplaceExisitingConstants = true
        if FileManager.default.fileExists(atPath: documentsConstantsURL.path),
            let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL),
            let documentsConstantsVersions = documentsConstants["Version"] as? Int {
            print("WKRUIConstants: Existing constants (v\(documentsConstantsVersions)) @ \(documentsConstantsURL.path)")
            if newConstantsVersion <= documentsConstantsVersions {
                shouldReplaceExisitingConstants = false
            }
        }

        print("WKRUIConstants: Replacing existing constants with bundled: \(shouldReplaceExisitingConstants)")
        if shouldReplaceExisitingConstants {
            do {
                try? FileManager.default.removeItem(at: documentsPreHideScriptURL)
                try FileManager.default.copyItem(at: newPreHideScriptFileURL, to: documentsPreHideScriptURL)

                try? FileManager.default.removeItem(at: documentsPostHideScriptURL)
                try FileManager.default.copyItem(at: newPostHideScriptFileURL, to: documentsPostHideScriptURL)

                try? FileManager.default.removeItem(at: documentsConstantsURL)
                try FileManager.default.copyItem(at: newConstantsFileURL, to: documentsConstantsURL)
            } catch {
                fatalError("WKRUIConstants: Something really bad happened")
            }
        }

        current = WKRUIConstants()
    }

    static private func copyBundledResourcesToDocuments() {
        guard let bundle = Bundle(identifier: "com.andrewfinke.WKRUIKit"),
            let bundledPlistURL = bundle.url(forResource: "WKRUIConstants", withExtension: "plist"),
            let bundledPreHideScriptURL = bundle.url(forResource: "WKRPreHideScript", withExtension: "js"),
            let bundledPostHideScriptURL = bundle.url(forResource: "WKRPostHideScript", withExtension: "js") else {
                fatalError()
        }

        copyIfNewer(newConstantsFileURL: bundledPlistURL,
                      newPreHideScriptFileURL: bundledPreHideScriptURL,
                      newPostHideScriptFileURL: bundledPostHideScriptURL)
    }

    internal func preHideScript() -> String {
        //swiftlint:disable:next line_length
        guard let documentsScriptURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRPreHideScript.js"),
            let source = try? String(contentsOf: documentsScriptURL) else {
                fatalError()
        }
        return source
    }

    internal func postHideScript() -> String {
        //swiftlint:disable:next line_length
        guard let documentsScriptURL = FileManager.default.documentsDirectory?.appendingPathComponent("WKRPostHideScript.js"),
            let source = try? String(contentsOf: documentsScriptURL) else {
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
