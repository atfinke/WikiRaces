//
//  MPCHostViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/9/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import MultipeerConnectivity
import UIKit

internal class MPCHostViewController: StateLogTableViewController, MCSessionDelegate, MCNearbyServiceBrowserDelegate {

    // MARK: - Types

    private enum PeerState: String {
        case found
        case invited
        case joining
        case joined
        case declined
    }

    // MARK: - Properties

    private var peers = [MCPeerID: PeerState]()
    private var sortedPeers: [MCPeerID] {
        return peers.keys.sorted(by: { (lhs, rhs) -> Bool in
            lhs.displayName < rhs.displayName
        })
    }

    var peerID: MCPeerID?
    var session: MCSession?
    var serviceType: String?
    private var browser: MCNearbyServiceBrowser?

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
        PlayerAnalytics.log(event: .userAction(#function))
        PlayerAnalytics.log(event: .hostCancelledPreMatch)

        session?.disconnect()
        didCancelMatch?()
    }

    @IBAction func startMatch(_ sender: Any) {
        PlayerAnalytics.log(event: .userAction(#function))

        tableView.isUserInteractionEnabled = false

        let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityView.sizeToFit()
        activityView.startAnimating()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityView)
        navigationItem.leftBarButtonItem?.isEnabled = false

        guard let session = session else { fatalError("Session is nil") }
        do {
            // Participants move to the game view and wait for "real" data when they receive first data chunk
            try session.send(Data(bytes: [1]), toPeers: session.connectedPeers, with: .reliable)
            try session.send(Data(bytes: [1]), toPeers: session.connectedPeers, with: .reliable)
            try session.send(Data(bytes: [1]), toPeers: session.connectedPeers, with: .reliable)
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
    private func update(peerID: MCPeerID, to newState: PeerState?) {
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
                 withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            self.update(peerID: peerID, to: .found)
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if peers.isEmpty {
                return 1
            } else {
                return peers.count
            }
        } else {
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Choose 1 to 7 players"
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return """
            Make sure all players are on the same Wi-Fi network
            and have Bluetooth enabled for the best results.
            """
        } else {
            return "Practice your skills in solo races. Solo races will not count towards your stats."
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "soloCell", for: indexPath)
        } else if peers.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: "searchingCell", for: indexPath)
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        let peerID = sortedPeers[indexPath.row]
        guard let state = peers[peerID] else {
            fatalError("No state for peerID: \(peerID)")
        }

        cell.textLabel?.text = peerID.displayName
        if state == .found {
            cell.detailTextLabel?.text = nil
            cell.isUserInteractionEnabled = true
        } else {
            cell.detailTextLabel?.text = peers[peerID]?.rawValue.capitalized
            cell.isUserInteractionEnabled = state == .found
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerAnalytics.log(event: .userAction(#function))

        if indexPath.section == 1 {
            PlayerAnalytics.log(event: .hostStartedSoloMatch)

            session?.disconnect()
            didStartMatch?(true)
            return
        }

        // Hits this case when the "Searching..." placeholder cell is selected
        guard !peers.isEmpty else { return }

        let peerID = sortedPeers[indexPath.row]
        guard let session = session else {
            fatalError("Session is nil")
        }
        update(peerID: peerID, to: .invited)
        browser?.invitePeer(peerID, to: session, withContext: nil, timeout: 15.0)
        tableView.deselectRow(at: indexPath, animated: true)
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
