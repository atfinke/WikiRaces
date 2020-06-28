//
//  StatsViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class StatsViewController: UITableViewController {

    // MARK: - Types -

    private struct Section {
        let name: String
        let items: [Item]
    }

    private struct Item {
        let name: String
        let detail: String?
    }

    // MARK: - Properties -

    private static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()

    private var sections = [
        Section(
            name: "Overall",
            items: [
                Item(
                    name: "Races",
                    detail: formatted(for: [.soloRaces, .mpcRaces, .gkRaces], suffix: "Race")),
                Item(
                    name: "Multiplayer Races",
                    detail: formatted(for: [.mpcRaces, .gkRaces], suffix: "Race")),
                Item(
                    name: "Wiki Points",
                    detail: formatted(for: [.mpcPoints, .gkPoints], suffix: "Point")),
                Item(
                    name: "Points Per Race",
                    detail: String(format: "%.2f PPR", PlayerDatabaseStat.multiplayerAverage.value())),
                Item(
                    name: "Total Time",
                    detail: formatted(for: [.soloTotalTime, .mpcTotalTime, .gkTotalTime], suffix: "S", checkPlural: false)),
                Item(
                    name: "Pages Viewed",
                    detail: formatted(for: [.soloPages, .mpcPages, .gkPages], suffix: "Page"))
            ]),
        Section(
            name: "Solo",
            items: [
                Item(
                    name: "Races",
                    detail: formatted(for: .soloRaces, suffix: "Race")),
                Item(
                    name: "Total Time",
                    detail: formatted(for: .soloTotalTime, suffix: "S", checkPlural: false))
            ]),
        Section(
            name: "Private Races",
            items: [
                Item(
                    name: "Races",
                    detail: formatted(for: .mpcRaces, suffix: "Race")),
                Item(
                    name: "Points",
                    detail: formatted(for: .mpcPoints, suffix: "Point")),
                Item(
                    name: "First Place",
                    detail: formatted(for: .mpcRaceFinishFirst, suffix: "Time")),
                Item(
                    name: "Total Time",
                    detail: formatted(for: .mpcTotalTime, suffix: "S", checkPlural: false)),
                Item(
                    name: "Players Raced",
                    detail: nil)
            ]),
        Section(
            name: "Public Races",
            items: [
                Item(
                    name: "Races",
                    detail: formatted(for: .gkRaces, suffix: "Race")),
                Item(
                    name: "Points",
                    detail: formatted(for: .gkPoints, suffix: "Point")),
                Item(
                    name: "First Place",
                    detail: formatted(for: .gkRaceFinishFirst, suffix: "Time")),
                Item(
                    name: "Total Time",
                    detail: formatted(for: .gkTotalTime, suffix: "S", checkPlural: false)),
                Item(
                    name: "Players Raced",
                    detail: nil)
            ]),
        Section(
            name: "Other",
            items: [
                Item(
                    name: "Pixels Scrolled",
                    detail: formatted(for: [.soloPixelsScrolled, .mpcPixelsScrolled, .gkPixelsScrolled], suffix: "Pixel")),
                Item(
                    name: "Triggered Easter Egg",
                    detail: formatted(for: .triggeredEasterEgg, suffix: "Time")),
                Item(
                    name: "Needed Help",
                    detail: formatted(for: [.soloHelp, .mpcHelp, .gkHelp], suffix: "Time"))
            ])
    ]

    // MARK: - Initalization -

    init() {
        super.init(style: .grouped)
        title = "Stats".uppercased()
        navigationItem.rightBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(done))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource -

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].name
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        let item = sections[indexPath.section].items[indexPath.row]
        cell.textLabel?.text = item.name

        if let detail = item.detail {
            cell.detailTextLabel?.text = detail
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .none
        } else {
            cell.detailTextLabel?.text = nil
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let controller = StatsPlayersViewController(mpc: indexPath.section == 2)
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Help -

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Formatting -

    static func formatted(for value: Double, suffix: String?, checkPlural: Bool) -> String {
        let rounded = Int(value)
        guard let str = formatter.string(from: NSNumber(value: rounded)) else { fatalError() }
        if let suffix = suffix {
            if rounded == 1 || !checkPlural {
                return str + " " + suffix
            } else {
                return str + " " + suffix + "s"
            }
        } else {
            return str
        }

    }

    static func formatted(for item: PlayerDatabaseStat, suffix: String?, checkPlural: Bool = true) -> String {
        return formatted(for: item.value(), suffix: suffix, checkPlural: checkPlural)
    }

    static func formatted(for items: [PlayerDatabaseStat], suffix: String?, checkPlural: Bool = true) -> String {
        var value = Double()
        items.forEach { value += $0.value() }
        return formatted(for: value, suffix: suffix, checkPlural: checkPlural)
    }

}
