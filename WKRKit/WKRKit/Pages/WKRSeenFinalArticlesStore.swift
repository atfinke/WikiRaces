//
//  WKRSeenFinalArticlesStore.swift
//  WKRKit
//
//  Created by Andrew Finke on 1/30/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation

public struct WKRSeenFinalArticlesStore {

    // MARK: - Types

    private struct RemoteTransfer: Codable {
        internal let articles: [String]
    }

    // MARK: - Properties

    private static let defaults = UserDefaults.standard
    private static let localPlayersSeenFinalArticlesKey = "WKRKit-LocalPlayerSeenFinalArticles"
    private static var localPlayersSeenFinalArticles: [String] {
        get {
            return defaults.stringArray(forKey: localPlayersSeenFinalArticlesKey) ?? []
        }
        set {
            defaults.setValue(newValue, forKey: localPlayersSeenFinalArticlesKey)
        }
    }
    private static var uniqueRemotePlayersSeenFinalArticles = Set<String>()

    // MARK: - Helpers

    internal static func unseenArticles() -> [String] {
        var finalArticles = Set(WKRKitConstants.current.finalArticles)

        let minCount = 50

        // make sure at least minCount unseen articles left before removing locally seen
        if localPlayersSeenFinalArticles.count < finalArticles.count - minCount {
            // remove local seen articles from final list
            finalArticles = finalArticles.subtracting(localPlayersSeenFinalArticles)
        } else {
            // player has seen almost all articles already
            resetLocalPlayerSeenFinalArticles()
        }

        // make sure at least minCount unseen articles left before removing remotely seen
        if uniqueRemotePlayersSeenFinalArticles.count < finalArticles.count - minCount {
            finalArticles = finalArticles.subtracting(uniqueRemotePlayersSeenFinalArticles)
        }

        return Array(finalArticles)
    }

    // MARK: - Local Player

    public static func encodedLocalPlayerSeenFinalArticles() -> Data? {
        let object = RemoteTransfer(articles: localPlayersSeenFinalArticles)
        return try? JSONEncoder().encode(object)
    }

    internal static func addLocalPlayerSeenFinalPages(_ newSeenFinalPages: [WKRPage]) {
        let paths = newSeenFinalPages.map({ "/" + $0.url.lastPathComponent })
        var articles = localPlayersSeenFinalArticles
        articles.append(contentsOf: paths)
        localPlayersSeenFinalArticles = Array(Set(articles))
    }

    private static func resetLocalPlayerSeenFinalArticles() {
        localPlayersSeenFinalArticles = []
    }

    // MARK: - Remote Players

    public static func addRemoteTransferData(_ data: Data) {
        guard let tranfer = try? JSONDecoder().decode(RemoteTransfer.self, from: data) else { return }

        // 1. Add new paths
        // 2. Remove copies from remote array that are already in local array
        uniqueRemotePlayersSeenFinalArticles = uniqueRemotePlayersSeenFinalArticles
            .union(tranfer.articles)
            .subtracting(localPlayersSeenFinalArticles)
    }

    public static func isRemoteTransferData(_ data: Data) -> Bool {
        guard let _ = try? JSONDecoder().decode(RemoteTransfer.self, from: data) else { return false }
        return true
    }

    public static func resetRemotePlayersSeenFinalArticles() {
        uniqueRemotePlayersSeenFinalArticles = []
    }

}
