//
//  WKRMultiWindowNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

final internal class WKRSplitViewNetwork: WKRPeerNetwork {

     // MARK: - Closures

    var networkUpdate: ((WKRPeerNetworkUpdate) -> Void)?

    // MARK: - Types

    private class WKRSplitMessage: NSObject {
        let sender: String
        let data: Data

        init(_ sender: String, _ data: Data) {
            self.sender = sender
            self.data = data
        }
    }

    // MARK: - Properties

    let isHost: Bool
    let playerName: String

    var players = [WKRPlayerProfile]()

    // MARK: - Initialization

    init(playerName: String, isHost: Bool) {
        self.playerName = playerName
        self.isHost = isHost

        let localPlayer = WKRPlayerProfile(name: playerName, playerID: playerName)
        players.append(localPlayer)

        NotificationCenter.default
            .addObserver(forName: Notification.Name("Object"), object: nil, queue: nil) { notification in
                let splitMessage = notification.object as! WKRSplitMessage
                let messageSender = WKRPlayerProfile(name: splitMessage.sender, playerID: splitMessage.sender)

                if splitMessage.sender != playerName {
                    if !self.players.contains(messageSender) {
                        self.players.append(messageSender)
                        self.networkUpdate?(.playerConnected(profile: messageSender))
                    }
                    do {
                        let object = try WKRCodable.decoder.decode(WKRCodable.self, from: splitMessage.data)
                        self.networkUpdate?(.object(object, profile: messageSender))
                    } catch {
                        fatalError(splitMessage.description)
                    }
                }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.networkUpdate?(.playerConnected(profile: localPlayer))
        }
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        guard let data = try? WKRCodable.encoder.encode(object) else { return }

        let splitMessage = WKRSplitMessage(playerName, data)
        let messageSender = WKRPlayerProfile(name: splitMessage.sender, playerID: splitMessage.sender)

        DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 / Double(arc4random() % 100))) {
            NotificationCenter.default.post(name: Notification.Name("Object"),
                                            object: splitMessage,
                                            userInfo: nil)
        }
        networkUpdate?(.object(object, profile: messageSender))
    }

    func disconnect() {
        print("Would Disconnect")
    }

    func hostNetworkInterface() -> UIViewController? {
        return nil
    }

}
