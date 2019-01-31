//
//  MPCHostViewController+Table.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

extension MPCHostViewController {

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
            return " "
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "soloCell", for: indexPath)
            cell.backgroundColor = UIColor.wkrBackgroundColor
            return cell
        } else if peers.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: MPCHostSearchingCell.reuseIdentifier, for: indexPath)
        }

        //swiftlint:disable:next line_length
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MPCHostPeerStateCell.reuseIdentifier, for: indexPath) as? MPCHostPeerStateCell else {
            fatalError()
        }

        let peerID = sortedPeers[indexPath.row]
        guard let state = peers[peerID] else {
            fatalError("No state for peerID: \(peerID)")
        }

        cell.peerLabel.text = peerID.displayName
        if state == .found {
            cell.detailLabel.text = nil
            cell.isUserInteractionEnabled = true
        } else {
            cell.detailLabel.text = peers[peerID]?.rawValue.capitalized
            cell.isUserInteractionEnabled = state == .found
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        PlayerMetrics.log(event: .userAction(#function))

        if indexPath.section == 1 {
            PlayerMetrics.log(event: .hostStartedSoloMatch)

            session?.disconnect()
            didStartMatch?(true)
            tableView.isUserInteractionEnabled = false
            return
        }

        // Hits this case when the "Searching..." placeholder cell is selected
        guard !peers.isEmpty else { return }

        let peerID = sortedPeers[indexPath.row]
        guard let session = session else {
            fatalError("Session is nil")
        }

        if session.connectedPeers.map({ $0.displayName }).contains(peerID.displayName) {
            let alertController = UIAlertController(title: "Duplicate Name",
                                                    message: "Player has the same name as another player in the match.",
                                                    preferredStyle: .alert)
            alertController.addCancelAction(title: "Ok")
            present(alertController, animated: true, completion: nil)
        }

        update(peerID: peerID, to: .invited)

        guard let bundleBuildString = Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            let bundleBuild = Int(bundleBuildString),
            let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
                fatalError("No bundle info dictionary")
        }
        let context = MPCHostContext(appBuild: bundleBuild,
                                     appVersion: bundleVersion,
                                     name: session.myPeerID.displayName,
                                     minPeerAppBuild: 3706)
        guard let data = try? JSONEncoder().encode(context) else {
            fatalError("Couldn't encode context")
        }

        browser?.invitePeer(peerID, to: session, withContext: data, timeout: 15.0)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
