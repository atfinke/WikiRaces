//
//  WKRMultiWindowNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation

class WKRSplitViewNetwork: WKRPeerNetwork {

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

    var totalData = 0
    weak var delegate: WKRPeerNetworkDelegate?

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
                        self.delegate?.network(self, playerConnected: messageSender)
                    }
                    do {
                        let object = try WKRCodable.decoder.decode(WKRCodable.self, from: splitMessage.data)
                        self.delegate?.network(self, didReceive: object, fromPlayer: messageSender)
                    } catch {
                        fatalError(splitMessage.description)
                    }
                }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.delegate?.network(self, playerConnected: localPlayer)
        }
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            let formatter = ByteCountFormatter()
            _debugLog("Total bytes sent: \(formatter.string(fromByteCount: Int64(self.totalData)))")
        }
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        _debugLog(object)
        guard let data = try? WKRCodable.encoder.encode(object) else { return }

        let splitMessage = WKRSplitMessage(playerName, data)
        let messageSender = WKRPlayerProfile(name: splitMessage.sender, playerID: splitMessage.sender)

        NotificationCenter.default.post(name: Notification.Name("Object"), object: splitMessage, userInfo: nil)
        delegate?.network(self, didReceive: object, fromPlayer: messageSender)

        totalData += data.count
    }

    func disconnect() {
        fatalError()
    }

    func presentNetworkInterface(on viewController: UIViewController) {
        fatalError()
    }

}

extension WKRManager {

    @available(*, deprecated, message: "Only for split view debugging")
    //swiftlint:disable:next identifier_name
    public convenience init(_playerName: String, isHost: Bool,
                            stateUpdate: @escaping ((WKRGameState) -> Void),
                            playersUpdate: @escaping (([WKRPlayer]) -> Void)) {

        let player = WKRPlayer(profile: WKRPlayerProfile(name: _playerName, playerID: _playerName), isHost: isHost)
        let network = WKRSplitViewNetwork(playerName: _playerName, isHost: isHost)

        self.init(player: player, network: network, stateUpdate: stateUpdate, playersUpdate: playersUpdate)
    }

}
