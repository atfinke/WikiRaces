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
    static let webViewAnimateOutDuration  = 0.25

    static let progessViewAnimateOutDelay     = 0.85
    static let progessViewAnimateOutDuration  = 0.4

    static let alertLabelHeight: CGFloat   = 30.0
    static let alertAnimateInDuration      = 0.25
    static let alertAnimateOutDuration     = 0.25
    public static let alertDefaultDuration = 5.0

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

            guard let recordConstantsAsset = record["ConstantsFile"] as? CKAsset,
                let recordStyleScriptAsset = record["StyleScriptFile"] as? CKAsset,
                let recordStyleScriptDarkAsset = record["StyleScriptDarkFile"] as? CKAsset,
                let recordCleanScriptAsset = record["CleanScriptFile"] as? CKAsset,
                let recordContentBlockerAsset = record["ContentBlockerFile"] as? CKAsset else {
                    return
            }

            DispatchQueue.main.async {
                copyIfNewer(newConstantsFileURL: recordConstantsAsset.fileURL,
                            newStyleScriptFileURL: recordStyleScriptAsset.fileURL,
                            newStyleScriptDarkFileURL: recordStyleScriptDarkAsset.fileURL,
                            newCleanScriptFileURL: recordCleanScriptAsset.fileURL,
                            newContentBlockerFileURL: recordContentBlockerAsset.fileURL)
            }
        }
    }

    static private func copyIfNewer(newConstantsFileURL: URL,
                                    newStyleScriptFileURL: URL,
                                    newStyleScriptDarkFileURL: URL,
                                    newCleanScriptFileURL: URL,
                                    newContentBlockerFileURL: URL) {

        guard FileManager.default.fileExists(atPath: newConstantsFileURL.path),
            FileManager.default.fileExists(atPath: newStyleScriptFileURL.path),
            FileManager.default.fileExists(atPath: newStyleScriptDarkFileURL.path),
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
        let documentsStyleScriptDarkURL = documentsPath(for: "WKRStyleScript-Dark.js")
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

                try? FileManager.default.removeItem(at: documentsStyleScriptDarkURL)
                try FileManager.default.copyItem(at: newStyleScriptDarkFileURL, to: documentsStyleScriptDarkURL)

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
            let bundledStyleScriptDarkURL = bundle.url(forResource: "WKRStyleScript-Dark", withExtension: "js"),
            let bundledCleanScriptURL = bundle.url(forResource: "WKRCleanScript", withExtension: "js"),
            let bundledContentBlockerURL = bundle.url(forResource: "WKRContentBlocker", withExtension: "json") else {
                fatalError("Failed to load bundled constants")
        }

        copyIfNewer(newConstantsFileURL: bundledPlistURL,
                    newStyleScriptFileURL: bundledStyleScriptURL,
                    newStyleScriptDarkFileURL: bundledStyleScriptDarkURL,
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

    internal func styleScriptDark() -> String {
        guard let source = try? String(contentsOf: WKRUIKitConstants.documentsPath(for: "WKRStyleScript-Dark.js")) else {
            fatalError("Failed to load style script dark")
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
            fatalError("Failed to load style script")
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
