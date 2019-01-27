//
//  WKRGameKitNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import Foundation
import GameKit

internal class WKRGameKitNetwork: NSObject, GKMatchDelegate, WKRPeerNetwork {

    // MARK: - Closures

    var objectReceived: ((WKRCodable, WKRPlayerProfile) -> Void)?
    var playerConnected: ((WKRPlayerProfile) -> Void)?
    var playerDisconnected: ((WKRPlayerProfile) -> Void)?

    // MARK: - Properties

    private weak var match: GKMatch?

    // MARK: - Initialization

    init(match: GKMatch) {
        self.match = match
        super.init()
        match.delegate = self
    }

    // MARK: - WKRNetwork

    func disconnect() {
        match?.disconnect()
    }

    func send(object: WKRCodable) {
        guard let match = match, let data = try? WKRCodable.encoder.encode(object) else { return }
        do {
            try match.sendData(toAllPlayers: data, with: .reliable)
            objectReceived?(object, GKLocalPlayer.local.wkrProfile())
        } catch {
            print(error)
        }
    }

    internal func hostNetworkInterface() -> UIViewController? {
//        guard let session = session else { fatalError("Session is nil") }
//        let browserViewController = MCBrowserViewController(serviceType: serviceType, session: session)
//        browserViewController.maximumNumberOfPeers = 8
//        browserViewController.delegate = self
//        return browserViewController
        return UIViewController()
    }

    // MARK: - MCSessionDelegate

    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        do {
            let object = try WKRCodable.decoder.decode(WKRCodable.self, from: data)
            objectReceived?(object, player.wkrProfile())
        } catch {
            print(data.description)
        }
    }

    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected: self.playerConnected?(player.wkrProfile())
            case .disconnected: self.playerDisconnected?(player.wkrProfile())
            default: break
            }

//            what is this??
//            if session.connectedPeers.isEmpty {
//                self.playerDisconnected?(WKRPlayerProfile(peerID: session.myPeerID))
//            }
        }
    }

    // MARK: - MCBrowserViewControllerDelegate

//    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
//        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
//    }
//
//    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
//        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
//    }

}

// MARK: - WKRKit Extensions

extension GKPlayer {
    func wkrProfile() -> WKRPlayerProfile {
        return WKRPlayerProfile(name: alias, playerID: playerID)
    }
}
