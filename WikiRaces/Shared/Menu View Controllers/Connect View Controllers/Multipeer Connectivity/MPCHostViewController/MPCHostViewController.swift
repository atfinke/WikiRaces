//
//  MPCHostViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/9/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity
import UIKit

import WKRKit
import WKRUIKit

#if !MULTIWINDOWDEBUG
import FirebasePerformance
#endif

internal class MPCHostViewController: UITableViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate {

    // MARK: - Types

    enum PeerState: String {
        case found
        case invited
        case joining
        case joined
        case declined
    }

    enum ListenerUpdate {
        case startMatch(isSolo: Bool)
        case cancel
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

    var listenerUpdate: ((ListenerUpdate) -> Void)?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "INVITE NEARBY PLAYERS"

        guard let peerID = peerID, let serviceType = serviceType else {
            fatalError("Required properties peerID or serviceType not set")
        }
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser?.delegate = self
        session?.delegate = self

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                           target: self,
                                                           action: #selector(cancelMatch(_:)))

        let startButton = UIBarButtonItem(barButtonSystemItem: .play,
                                          target: self,
                                          action: #selector(startMatch(_:)))
        startButton.isEnabled = false
        navigationItem.rightBarButtonItem = startButton
        navigationController?.navigationBar.barStyle = UIBarStyle.wkrStyle

        tableView.backgroundColor = WKRUIStyle.isDark ? UIColor.wkrBackgroundColor : UIColor.groupTableViewBackground

        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(MPCHostPeerStateCell.self,
                           forCellReuseIdentifier: MPCHostPeerStateCell.reuseIdentifier)
        tableView.register(MPCHostSearchingCell.self,
                           forCellReuseIdentifier: MPCHostSearchingCell.reuseIdentifier)
        tableView.register(MPCHostSoloCell.self,
                           forCellReuseIdentifier: MPCHostSoloCell.reuseIdentifier)
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

    @objc
    func cancelMatch(_ sender: Any) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))
        PlayerAnonymousMetrics.log(event: .hostCancelledPreMatch)

        session?.disconnect()
        listenerUpdate?(.cancel)
    }

    @objc
    func startMatch(_ sender: Any) {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        tableView.isUserInteractionEnabled = false

        let activityView = UIActivityIndicatorView(style: .gray)
        activityView.color = UIColor.wkrActivityIndicatorColor
        activityView.sizeToFit()
        activityView.startAnimating()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        navigationItem.leftBarButtonItem?.isEnabled = false

        guard let session = session else { fatalError("Session is nil") }
        do {
            let message = ConnectViewController.StartMessage(hostName: session.myPeerID.displayName)
            let data = try JSONEncoder().encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)

            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.listenerUpdate?(.startMatch(isSolo: false))
            }
        } catch {
            let info = "startMatch: " + error.localizedDescription
            PlayerAnonymousMetrics.log(event: .error(info))

            session.disconnect()
            listenerUpdate?(.cancel)
        }
    }

    /// Updates the peerID to a new state and updates the table view
    ///
    /// - Parameters:
    ///   - peerID: Peer ID updated
    ///   - newState: The new state
    func update(peerID: MCPeerID, to newState: PeerState?) {
        let newStateString = String(describing: newState?.rawValue)
        PlayerAnonymousMetrics.log(event: .gameState("Peer Update: \(peerID.displayName) \(newStateString)"))

        guard let newState = newState else {
            if let index = sortedPeers.firstIndex(of: peerID) {
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
            if let index = sortedPeers.firstIndex(of: peerID) {
                tableView.reloadRows(at: [IndexPath(row: index)], with: .fade)
            } else {
                tableView.reloadData()
            }
        } else if peers[peerID] == nil {
            peers[peerID] = newState
            if let index = sortedPeers.firstIndex(of: peerID) {
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
        let info = "didNotStartBrowsingForPeers: " + error.localizedDescription
        PlayerAnonymousMetrics.log(event: .error(info))
        listenerUpdate?(.cancel)
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
            @unknown default:
                return
            }
        }
    }

    func session(_ session: MCSession,
                 didReceive data: Data,
                 fromPeer peerID: MCPeerID) {
        WKRSeenFinalArticlesStore.addRemoteTransferData(data)
    }

    // MARK: - Unused MCSessionDelegate

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
