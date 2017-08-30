//
//  WKRMultipeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class WKRMultipeerNetwork: NSObject, MCSessionDelegate, WKRPeerNetwork {

    // MARK: - Properties

    static let serviceType = "WKRPeer3.0"

    let isHost: Bool
    private let session: MCSession
    weak var delegate: WKRPeerNetworkDelegate?

    var connectedPlayers: Int {
        return session.connectedPeers.count
    }

    // MARK: - Initialization

    init(session: MCSession, isHost: Bool) {
        self.session = session
        self.isHost = isHost

        super.init()

        session.delegate = self
    }

    // MARK: - WKRNetwork

    func send(object: WKRCodable) {
        _debugLog(object)
        guard let data = try? WKRCodable.encoder.encode(object) else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            delegate?.network(self, didReceive: object, fromPlayer: WKRPlayerProfile(peerID: session.myPeerID))
        } catch {
            print(error)
        }
    }

    func presentNetworkInterface(on viewController: UIViewController) {
        let browserViewController = MCBrowserViewController(serviceType: WKRMultipeerNetwork.serviceType, session: session)
        browserViewController.maximumNumberOfPeers = 8
        browserViewController.delegate = self
        viewController.present(viewController, animated: true, completion: nil)
    }

    // MARK: - MCSessionDelegate

    open func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let object = try WKRCodable.decoder.decode(WKRCodable.self, from: data)
            delegate?.network(self, didReceive: object, fromPlayer: WKRPlayerProfile(peerID: session.myPeerID))
        } catch {
            fatalError(data.description)
        }
    }

    open func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        _debugLog(state)
        switch state {
        case .connected:
            delegate?.network(self, playerConnected: WKRPlayerProfile(peerID: peerID))
        case .notConnected:
            delegate?.network(self, playerDisconnected: WKRPlayerProfile(peerID: peerID))
        default: break
        }
    }

    // Not needed

    open func session(_ session: MCSession,
                      didStartReceivingResourceWithName resourceName: String,
                      fromPeer peerID: MCPeerID,
                      with progress: Progress) {
    }

    open func session(_ session: MCSession,
                      didFinishReceivingResourceWithName resourceName: String,
                      fromPeer peerID: MCPeerID,
                      at localURL: URL?,
                      withError error: Error?) {
    }

    open func session(_ session: MCSession,
                      didReceive stream: InputStream,
                      withName streamName: String,
                      fromPeer peerID: MCPeerID) {
    }

}

extension WKRMultipeerNetwork: MCBrowserViewControllerDelegate {
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }

}

extension WKRPlayerProfile {
    init(peerID: MCPeerID) {
        name = peerID.displayName
        playerID = peerID.hashValue.description
    }
}
