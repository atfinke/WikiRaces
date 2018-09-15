//
//  MPCHostViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/9/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity
import UIKit

#if !MULTIWINDOWDEBUG
import FirebasePerformance
#endif

internal class MPCHostViewController: StateLogTableViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate {

    // MARK: - Types

    enum PeerState: String {
        case found
        case invited
        case joining
        case joined
        case declined
    }

    // MARK: - Properties

    var peers = [MCPeerID: PeerState]()
    var sortedPeers: [MCPeerID] {
        return peers.keys.sorted(by: { (lhs, rhs) -> Bool in
            lhs.displayName < rhs.displayName
        })
    }

    #if !MULTIWINDOWDEBUG
    var peersConnectTraces = [MCPeerID: Trace]()
    #endif

    var peerID: MCPeerID?
    var session: MCSession?
    var serviceType: String?
    var browser: MCNearbyServiceBrowser?

    /// Called when the start button is pressed
    var didStartMatch: ((_ isSolo: Bool) -> Void)?
    /// Called when the cancel button is pressed
    var didCancelMatch: (() -> Void)?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let peerID = peerID, let serviceType = serviceType else {
            fatalError("Required properties peerID or serviceType not set")
        }
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        session?.delegate = self

        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationController?.navigationBar.barStyle = UIBarStyle.wkrStyle

        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MPCHostPeerStateCell.self,
                           forCellReuseIdentifier: MPCHostPeerStateCell.reuseIdentifier)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        browser?.startBrowsingForPeers()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        browser?.stopBrowsingForPeers()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    // MARK: - Actions

    @IBAction func cancelMatch(_ sender: Any) {
        PlayerMetrics.log(event: .userAction(#function))
        PlayerMetrics.log(event: .hostCancelledPreMatch)

        session?.disconnect()
        didCancelMatch?()
    }

    @IBAction func startMatch(_ sender: Any) {
        PlayerMetrics.log(event: .userAction(#function))

        tableView.isUserInteractionEnabled = false

        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.color = UIColor.wkrActivityIndicatorColor
        activityView.sizeToFit()
        activityView.startAnimating()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        navigationItem.leftBarButtonItem?.isEnabled = false

        guard let session = session else { fatalError("Session is nil") }
        do {
            // Participants move to the game view and wait for "real" data when they receive first data chunk
            let data = Data(bytes: [1])
            let peers = session.connectedPeers
            try session.send(data, toPeers: peers, with: .unreliable)
            try session.send(data, toPeers: peers, with: .reliable)
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.didStartMatch?(false)
            }
        } catch {
            session.disconnect()
            didCancelMatch?()
        }
    }

    /// Updates the peerID to a new state and updates the table view
    ///
    /// - Parameters:
    ///   - peerID: Peer ID updated
    ///   - newState: The new state
    func update(peerID: MCPeerID, to newState: PeerState?) {
        let newStateString = String(describing: newState?.rawValue)
        PlayerMetrics.log(event: .gameState("Peer Update: \(peerID.displayName) \(newStateString)"))

        guard let newState = newState else {
            if let index = sortedPeers.index(of: peerID) {
                peers[peerID] = nil
                if peers.isEmpty {
                    tableView.reloadRows(at: [IndexPath(row: index)], with: .fade)
                } else {
                    tableView.deleteRows(at: [IndexPath(row: index)], with: .fade)
                }
            }
            return
        }

        if let state = peers[peerID], state != newState {
            peers[peerID] = newState
            if let index = sortedPeers.index(of: peerID) {
                tableView.reloadRows(at: [IndexPath(row: index)], with: .fade)
            } else {
                tableView.reloadData()
            }
        } else if peers[peerID] == nil {
            peers[peerID] = newState
            if let index = sortedPeers.index(of: peerID) {
                if peers.count == 1 {
                    tableView.reloadRows(at: [IndexPath(row: index)], with: .fade)
                } else {
                    tableView.insertRows(at: [IndexPath(row: index)], with: .left)
                }
            } else {
                tableView.reloadData()
            }
        }
        navigationItem.rightBarButtonItem?.isEnabled = !peers.values.filter({ $0 == .joined }).isEmpty

        performaceTrace(peerID: peerID, newState: newState)
    }

    func performaceTrace(peerID: MCPeerID, newState: PeerState?) {
        #if !MULTIWINDOWDEBUG

        let hostInviteResponseTraceName = "Host Invite Response Trace"
        let hostInviteJoingTraceName = "Host Invite Joining Trace"

        if newState == .invited {
            peersConnectTraces[peerID] = Performance.startTrace(name: hostInviteResponseTraceName)
        } else if newState == .declined,
            let trace = peersConnectTraces[peerID],
            trace.name == hostInviteResponseTraceName {
            trace.stop()
        } else if newState == .joining,
            let trace = peersConnectTraces[peerID],
            trace.name == hostInviteResponseTraceName {
            trace.stop()
            peersConnectTraces[peerID] = Performance.startTrace(name: hostInviteJoingTraceName)
        } else if newState == .joined,
            let trace = peersConnectTraces[peerID],
            trace.name == hostInviteJoingTraceName {
            trace.stop()
        }

        #endif
    }

    // MARK: - MCNearbyServiceBrowserDelegate

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            let state = self.peers[peerID] ?? .found
            if state != .invited && state != .joining && state != .joined {
                self.update(peerID: peerID, to: nil)
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        didCancelMatch?()
    }

    func browser(_ browser: MCNearbyServiceBrowser,
                 foundPeer peerID: MCPeerID,
                 withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            self.update(peerID: peerID, to: .found)
        }
    }

    // MARK: - MCSessionDelegate

    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.update(peerID: peerID, to: .declined)
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            case .connecting:
                self.update(peerID: peerID, to: .joining)
            case .connected:
                self.update(peerID: peerID, to: .joined)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
    }

    // MARK: - Unused MCSessionDelegate

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession,
                 didReceive stream: InputStream,
                 withName streamName: String,
                 fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession,
                 didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 with progress: Progress) {}
    func session(_ session: MCSession,
                 didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID,
                 at localURL: URL?,
                 withError error: Error?) {}

}
