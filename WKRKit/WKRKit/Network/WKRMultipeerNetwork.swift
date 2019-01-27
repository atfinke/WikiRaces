//
//  WKRMultipeerNetwork.swift
//  WKRKit
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import Foundation
import MultipeerConnectivity

internal class WKRMultipeerNetwork: NSObject, MCSessionDelegate, MCBrowserViewControllerDelegate, WKRPeerNetwork {

    // MARK: - Closures

    var objectReceived: ((WKRCodable, WKRPlayerProfile) -> Void)?
    var playerConnected: ((WKRPlayerProfile) -> Void)?
    var playerDisconnected: ((WKRPlayerProfile) -> Void)?

    // MARK: - Properties

    private weak var session: MCSession?
    private let serviceType: String

    // MARK: - Initialization

    init(serviceType: String, session: MCSession) {
        self.serviceType = serviceType
        self.session = session
        super.init()
        session.delegate = self
    }

    // MARK: - WKRNetwork

    func disconnect() {
        session?.disconnect()
    }

    func send(object: WKRCodable) {
        guard let session = session, let data = try? WKRCodable.encoder.encode(object) else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            objectReceived?(object, session.myPeerID.wkrProfile())
        } catch {
            print(error)
        }
    }

    internal func hostNetworkInterface() -> UIViewController? {
        guard let session = session else { fatalError("Session is nil") }
        let browserViewController = MCBrowserViewController(serviceType: serviceType, session: session)
        browserViewController.maximumNumberOfPeers = 8
        browserViewController.delegate = self
        return browserViewController
    }

    // MARK: - MCSessionDelegate

    open func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let object = try WKRCodable.decoder.decode(WKRCodable.self, from: data)
            objectReceived?(object, peerID.wkrProfile())
        } catch {
            print(data.description)
        }
    }

    open func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected: self.playerConnected?(peerID.wkrProfile())
            case .notConnected: self.playerDisconnected?(peerID.wkrProfile())
            default: break
            }

            if session.connectedPeers.isEmpty {
                self.playerDisconnected?(session.myPeerID.wkrProfile())
            }
        }
    }

    // MARK: - MCBrowserViewControllerDelegate

    public func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    public func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.presentingViewController?.dismiss(animated: true, completion: nil)
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

// MARK: - WKRKit Extensions

extension MCPeerID {
    func wkrProfile() -> WKRPlayerProfile {
        return WKRPlayerProfile(name: displayName, playerID: hashValue.description)
    }
}
