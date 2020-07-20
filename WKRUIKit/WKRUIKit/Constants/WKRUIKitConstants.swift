//
//  WKRUIKitConstants.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import CloudKit
import Foundation

public struct WKRUIKitConstants {

    // MARK: - Not Updated OTA

    static let webViewAnimateInDuration   = 0.25
    static let webViewAnimateOutDuration  = 0.15

    static let progessViewAnimateOutDelay     = 0.85
    static let progessViewAnimateOutDuration  = 0.4

    static let alertViewHeight: CGFloat = 50.0
    static let alertViewImageHeight: CGFloat = 22
    static let alertViewImagePadding: CGFloat = 6
    static let alertAnimateInDuration      = 0.2
    static let alertAnimateOutDuration     = 0.15
    public static let alertDefaultDuration = 3.0

    // MARK: - Updated OTA

    public let version: Int
    public static var current = WKRUIKitConstants()

    init() {
        let documentsConstantsURL = WKRUIKitConstants.documentsPath(for: "WKRUIConstants.plist")
        guard let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL) as? [String: Any] else {
            fatalError("Failed to load constants")
        }

        guard let version = documentsConstants["Version"] as? Int else {
            fatalError("WKRUIConstants: No Version value")
        }

        self.version = version
    }

    static public func updateConstants() {
        copyBundledResourcesToDocuments()

        guard ProcessInfo.processInfo.environment["Cloud_Disabled"] != "true" else {
            return
        }

        let publicDB = CKContainer.default().publicCloudDatabase
        let recordID = CKRecord.ID(recordName: "WKRUIKitConstantsv2")

        publicDB.fetch(withRecordID: recordID) { record, _ in
            guard let record = record else {
                return
            }

            guard let recordConstantsAssetURL = (record["ConstantsFile"] as? CKAsset)?.fileURL,
                  let recordStyleScriptAssetURL = (record["StyleScriptFile"] as? CKAsset)?.fileURL,
                  let recordCleanScriptAssetURL = (record["CleanScriptFile"] as? CKAsset)?.fileURL,
                  let recordContentBlockerAssetURL = (record["ContentBlockerFile"] as? CKAsset)?.fileURL else {
                return
            }

            DispatchQueue.main.async {
                copyIfNewer(newConstantsFileURL: recordConstantsAssetURL,
                            newStyleScriptFileURL: recordStyleScriptAssetURL,
                            newCleanScriptFileURL: recordCleanScriptAssetURL,
                            newContentBlockerFileURL: recordContentBlockerAssetURL)
            }
        }
    }

    static private func copyIfNewer(newConstantsFileURL: URL,
                                    newStyleScriptFileURL: URL,
                                    newCleanScriptFileURL: URL,
                                    newContentBlockerFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
              FileManager.default.fileExists(atPath: newStyleScriptFileURL.path),
              FileManager.default.fileExists(atPath: newCleanScriptFileURL.path),
              FileManager.default.fileExists(atPath: newContentBlockerFileURL.path) else {
            return
        }

        guard let newConstants = NSDictionary(contentsOf: newConstantsFileURL),
              let newConstantsVersion = newConstants["Version"] as? Int else {
            return
        }

        let documentsConstantsURL = documentsPath(for: "WKRUIConstants.plist")
        let documentsStyleScriptURL = documentsPath(for: "WKRStyleScript.js")
        let documentsCleanScriptURL = documentsPath(for: "WKRCleanScript.js")
        let documentsContentBlcokerURL = documentsPath(for: "WKRContentBlocker.json")

        var shouldReplaceExisitingConstants = true
        if FileManager.default.fileExists(atPath: documentsConstantsURL.path),
           let documentsConstants = NSDictionary(contentsOf: documentsConstantsURL),
           let documentsConstantsVersions = documentsConstants["Version"] as? Int {

            if newConstantsVersion <= documentsConstantsVersions {
                shouldReplaceExisitingConstants = false
            }
        }

        if ProcessInfo.processInfo.environment["Force_Update_UI"] == "true" {
            shouldReplaceExisitingConstants = true
        }

        if shouldReplaceExisitingConstants {
            do {
                try? FileManager.default.removeItem(at: documentsStyleScriptURL)
                try FileManager.default.copyItem(at: newStyleScriptFileURL, to: documentsStyleScriptURL)

                try? FileManager.default.removeItem(at: documentsCleanScriptURL)
                try FileManager.default.copyItem(at: newCleanScriptFileURL, to: documentsCleanScriptURL)

                try? FileManager.default.removeItem(at: documentsContentBlcokerURL)
                try FileManager.default.copyItem(at: newContentBlockerFileURL, to: documentsContentBlcokerURL)

                try? FileManager.default.removeItem(at: documentsConstantsURL)
                try FileManager.default.copyItem(at: newConstantsFileURL, to: documentsConstantsURL)
            } catch {
                return
            }
        }

        let newCurrentConstants = WKRUIKitConstants()
        WKRUIKitConstants.current = newCurrentConstants
    }

    static private func copyBundledResourcesToDocuments() {
        guard Thread.isMainThread,
              let bundle = Bundle(identifier: "com.andrewfinke.WKRUIKit"),
              let bundledPlistURL = bundle.url(forResource: "WKRUIConstants", withExtension: "plist"),
              let bundledStyleScriptURL = bundle.url(forResource: "WKRStyleScript", withExtension: "js"),
              let bundledCleanScriptURL = bundle.url(forResource: "WKRCleanScript", withExtension: "js"),
              let bundledContentBlockerURL = bundle.url(forResource: "WKRContentBlocker", withExtension: "json") else {
            fatalError("Failed to load bundled constants")
        }

        copyIfNewer(newConstantsFileURL: bundledPlistURL,
                    newStyleScriptFileURL: bundledStyleScriptURL,
                    newCleanScriptFileURL: bundledCleanScriptURL,
                    newContentBlockerFileURL: bundledContentBlockerURL)
    }

    // MARK: - Script Helpers

    internal func styleScript() -> String {
        guard let source = try? String(contentsOf: WKRUIKitConstants.documentsPath(for: "WKRStyleScript.js")) else {
            fatalError("Failed to load style script")
        }
        return source
    }

    internal func cleanScript() -> String {
        guard let source = try? String(contentsOf: WKRUIKitConstants.documentsPath(for: "WKRCleanScript.js")) else {
            fatalError("Failed to load style script")
        }
        return source
    }

    internal func contentBlocker() -> String {
        guard let source = try? String(contentsOf: WKRUIKitConstants.documentsPath(for: "WKRContentBlocker.json")) else {
            fatalError("Failed to load blocker script")
        }
        return source
    }

    static func documentsPath(for fileName: String) -> URL {
        guard let docs = FileManager.default.documentsDirectory else { fatalError() }
        return docs.appendingPathComponent(fileName)
    }

}

extension FileManager {
    var documentsDirectory: URL? {
        return urls(for: .documentDirectory, in: .userDomainMask).first
    }
}
