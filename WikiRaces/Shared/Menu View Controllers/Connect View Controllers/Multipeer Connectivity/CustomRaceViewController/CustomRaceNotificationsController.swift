//
//  CustomRaceNotificationsController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final class CustomRaceNotificationsController: UITableViewController {

    // MARK: - Types -

    private class Cell: UITableViewCell {

        // MARK: - Properties -

        let toggle = UISwitch()
        static let reuseIdentifier = "reuseIdentifier"

        // MARK: - Initalization -

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(toggle)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - View Life Cycle -

        override func layoutSubviews() {
            super.layoutSubviews()
            toggle.onTintColor = .wkrTextColor(for: traitCollection)

            toggle.center = CGPoint(
                x: contentView.frame.width - contentView.layoutMargins.right - toggle.frame.width / 2,
                y: contentView.frame.height / 2)
        }
    }

    // MARK: - Properties -

    var notifications: WKRGameSettings.Notifications {
        didSet {
            didUpdate?(notifications)
        }
    }
    var didUpdate: ((WKRGameSettings.Notifications) -> Void)?

    // MARK: - Initalization -

    init(notifications: WKRGameSettings.Notifications) {
        self.notifications = notifications
        super.init(style: .grouped)
        title = "Player Messages".uppercased()
        tableView.allowsSelection = false
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier,
                                                       for: indexPath) as? Cell else {
                                                        fatalError()
        }
        cell.toggle.tag = indexPath.row
        cell.toggle.addTarget(self, action: #selector(switchChanged(updatedSwitch:)), for: .valueChanged)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Player needed help"
            cell.toggle.isOn = notifications.neededHelp
        case 1:
            cell.textLabel?.text = "Player is close"
            cell.toggle.isOn = notifications.linkOnPage
        case 2:
            cell.textLabel?.text = "Player missed the link"
            cell.toggle.isOn = notifications.missedLink
        case 3:
            cell.textLabel?.text = "Player is on USA"
            cell.toggle.isOn = notifications.isOnUSA
        case 4:
            cell.textLabel?.text = "Player is on same page"
            cell.toggle.isOn = notifications.isOnSamePage
        default:
            fatalError()
        }

        return cell
    }

    // MARK: - Helpers -

    @objc
    func switchChanged(updatedSwitch: UISwitch) {
        notifications = WKRGameSettings.Notifications(
            neededHelp: updatedSwitch.tag == 0 ? updatedSwitch.isOn : notifications.neededHelp,
            linkOnPage: updatedSwitch.tag == 1 ? updatedSwitch.isOn : notifications.linkOnPage,
            missedTheLink: updatedSwitch.tag == 2 ? updatedSwitch.isOn : notifications.missedLink,
            isOnUSA: updatedSwitch.tag == 3 ? updatedSwitch.isOn : notifications.isOnUSA,
            isOnSamePage: updatedSwitch.tag == 4 ? updatedSwitch.isOn : notifications.isOnSamePage)
    }

}
