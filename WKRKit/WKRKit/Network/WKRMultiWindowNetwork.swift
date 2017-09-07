//
//  WKRMultiWindowNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

class WKRSplitViewNetwork: WKRPeerNetwork {

     // MARK: - Closures

    var objectReceived: ((WKRCodable, WKRPlayerProfile) -> Void)?
    var playerConnected: ((WKRPlayerProfile) -> Void)?
    var playerDisconnected: ((WKRPlayerProfile) -> Void)?

    // MARK: Types

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
    var connectedPlayers: Int {
        return players.count
    }

    // MARK: - Initialization

    init(playerName: String, isHost: Bool) {
        self.playerName = playerName
        self.isHost = isHost

        let localPlayer = WKRPlayerProfile(name: playerName, playerID: playerName)
        players.append(localPlayer)

        //swiftlint:disable:next discarded_notification_center_observer
        NotificationCenter.default
            .addObserver(forName: Notification.Name("Object"), object: nil, queue: nil) { notification in
                //swiftlint:disable:next force_cast
                let splitMessage = notification.object as! WKRSplitMessage
                let messageSender = WKRPlayerProfile(name: splitMessage.sender, playerID: splitMessage.sender)

                if splitMessage.sender != playerName {
                    if !self.players.contains(messageSender) {
                        self.players.append(messageSender)
                        self.playerConnected?(messageSender)
                    }
                    do {
                        let object = try WKRCodable.decoder.decode(WKRCodable.self, from: splitMessage.data)
                        self.objectReceived?(object, messageSender)
                    } catch {
                        fatalError(splitMessage.description)
                    }
                }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.playerConnected?(localPlayer)
        }
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        guard let data = try? WKRCodable.encoder.encode(object) else { return }

        let splitMessage = WKRSplitMessage(playerName, data)
        let messageSender = WKRPlayerProfile(name: splitMessage.sender, playerID: splitMessage.sender)

        DispatchQueue.main.asyncAfter(deadline: .now() + (1.5 / Double(arc4random() % 100))) {
            NotificationCenter.default.post(name: Notification.Name("Object"), object: splitMessage, userInfo: nil)
        }
        objectReceived?(object, messageSender)
    }

    func disconnect() {
        fatalError()
    }

    func hostNetworkInterface() -> UIViewController {
        fatalError()
    }

}

// MARK: - WKRKit Extensions

extension WKRManager {

    @available(*, deprecated, message: "Only for split view debugging")
    public convenience init(windowName: String,
                            isPlayerHost: Bool,
                            stateUpdate: @escaping ((WKRGameState) -> Void),
                            playersUpdate: @escaping (([WKRPlayer]) -> Void)) {

        let player = WKRPlayer(profile: WKRPlayerProfile(name: windowName, playerID: windowName), isHost: isPlayerHost)
        let network = WKRSplitViewNetwork(playerName: windowName, isHost: isPlayerHost)

        self.init(player: player, network: network, stateUpdate: stateUpdate, playersUpdate: playersUpdate)
    }

}
