//
//  MPCHostViewController+Table.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import WKRKit

extension MPCHostViewController {

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
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
        } else if section == 1 {
            return nil
        } else if section == 2 {
            return nil
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Make sure all players are on the same Wi-Fi network and have Bluetooth enabled for the best results."
        } else if section == 1 {
            return "Automatically invite nearby players to the race."
        } else if section == 2 {
            return nil
        } else {
            return "Practice your skills in solo races. Solo races will not count towards your stats."
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MPCHostAutoInviteCell.reuseIdentifier,
                                                           for: indexPath) as? MPCHostAutoInviteCell else {
                                                            fatalError()
            }
            cell.isEnabled = isAutoInviteOn
            cell.onToggle = { [weak self] toggle in
                self?.isAutoInviteOn = toggle
                PlayerAnonymousMetrics.log(event: .autoInviteToggled)
            }
            return cell
        } else if indexPath.section == 2 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Customize Race"
            cell.detailTextLabel?.text = gameSettings.isCustom ? "Custom" : "Standard"
            cell.accessoryType = .disclosureIndicator
            return cell
        } else if indexPath.section == 3 {
            return tableView.dequeueReusableCell(withIdentifier: MPCHostSoloCell.reuseIdentifier,
                                                 for: indexPath)
        } else if peers.isEmpty {
            return tableView.dequeueReusableCell(withIdentifier: MPCHostSearchingCell.reuseIdentifier,
                                                 for: indexPath)
        }

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
        if indexPath.section == 1 { return }

        PlayerAnonymousMetrics.log(event: .userAction(#function))

        if indexPath.section == 2 {
            PlayerAnonymousMetrics.log(event: .customRaceOpened)

            let controller = CustomRaceViewController(settings: gameSettings)
            controller.allCustomPages = allCustomPages
            navigationController?.pushViewController(controller, animated: true)
            self.gameSettingsController = controller
            return
        } else if indexPath.section == 3 {
            PlayerAnonymousMetrics.log(event: .hostStartedSoloMatch)

            session?.disconnect()
            listenerUpdate?(.startMatch(isSolo: true))
            tableView.isUserInteractionEnabled = false
            return
        }

        // Hits this case when the "Searching..." placeholder cell is selected
        guard !peers.isEmpty else { return }

        let peerID = sortedPeers[indexPath.row]
        invite(peerID: peerID)

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if (indexPath.section == 0 && peers.isEmpty) || indexPath.section == 1 {
            return 44.0
        }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    func invite(peerID: MCPeerID) {
        guard let session = session else {
            fatalError("Session is nil")
        }

        let maxPlayerCount = min(WKRKitConstants.current.maxLocalRacePlayers,
                                 kMCSessionMaximumNumberOfPeers)
        let peerCount = session.connectedPeers.count
        guard maxPlayerCount > peerCount + 1 else { return }

        if session.connectedPeers.map({ $0.displayName }).contains(peerID.displayName) {
            let alertController = UIAlertController(title: "Duplicate Name",
                                                    message: "Player has the same name as another player in the match.",
                                                    preferredStyle: .alert)
            alertController.addCancelAction(title: "Ok")
            present(alertController, animated: true, completion: nil)
        }

        update(peerID: peerID, to: .invited)

        let appInfo = Bundle.main.appInfo
        let context = MPCHostContext(appBuild: appInfo.build,
                                     appVersion: appInfo.version,
                                     name: session.myPeerID.displayName,
                                     inviteTimeout: 45.0,
                                     minPeerAppBuild: MPCHostContext.minBuildToJoinLocalHost)
        guard let data = try? JSONEncoder().encode(context) else {
            fatalError("Couldn't encode context")
        }

        browser?.invitePeer(peerID,
                            to: session,
                            withContext: data,
                            timeout: context.inviteTimeout)
    }

}
