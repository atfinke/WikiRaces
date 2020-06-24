//
//  HostViewController+Table.swift
//  WKRUIKit
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

extension HostViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else {
            fatalError()
        }
        
        switch section {
        case .customizeRace:
            return 1
        case .raceCode:
            return 2
        case .autoInvite:
            return 1
        case .players:
            return max(1, players.count)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
        case .customizeRace:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.textLabel?.text = "Customize"
                            cell.detailTextLabel?.text = gameSettings.isCustom ? "Custom" : "Standard"
            cell.accessoryType = .disclosureIndicator
            return cell
        case .raceCode:
            if indexPath.row == 0 {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "Invite Code"
                cell.detailTextLabel?.text = raceCode ?? "-"
                cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.isUserInteractionEnabled = false
                raceCodeLabel = cell.detailTextLabel
                return cell
            } else {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "Share Link"
                cell.textLabel?.textColor = cell.textLabel?.tintColor
                return cell
            }
        case .autoInvite:
            let cell = HostAutoInviteNearbyCell()
            cell.isEnabled = Defaults.isAutoInviteOn
            cell.onToggle = { toggle in
                Defaults.isAutoInviteOn = toggle
                PlayerAnonymousMetrics.log(event: .autoInviteToggled)
            }
            cell.isUserInteractionEnabled = true
            return cell
        case .players:
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            if players.isEmpty {
                cell.textLabel?.text = "No Connected Racers"
                cell.textLabel?.textColor = .secondaryLabel
            } else {
                cell.textLabel?.text = players[indexPath.row].alias
            }
            return cell
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Section(rawValue: indexPath.section) else {
            fatalError()
        }
        
        switch section {
        case .customizeRace:
            let controller = CustomRaceViewController(settings: gameSettings)
            controller.allCustomPages = allCustomPages
            navigationController?.pushViewController(controller, animated: true)
            self.gameSettingsController = controller
        case .raceCode:
            guard let code = raceCode, let url = URL(string: "wikiraces://invite?code=\(code)") else {
                fatalError()
            }
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
            present(controller, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        case .autoInvite:
            break
        case .players:
            fatalError()
            
        }
    }
    
}
