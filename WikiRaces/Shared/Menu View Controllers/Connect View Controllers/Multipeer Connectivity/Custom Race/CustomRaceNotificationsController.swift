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

        let switchElement = UISwitch()
        static let reuseIdentifier = "reuseIdentifier"

        // MARK: - Initalization -

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(switchElement)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - View Life Cycle -

        override func layoutSubviews() {
            super.layoutSubviews()
            switchElement.center = CGPoint(
                x: contentView.frame.width - contentView.layoutMargins.right - switchElement.frame.width / 2,
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
        title = "Player Messages"
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
        cell.switchElement.tag = indexPath.row
        cell.switchElement.addTarget(self, action: #selector(switchChanged(updatedSwitch:)), for: .valueChanged)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "X Needed Help"
            cell.switchElement.isOn = notifications.neededHelp
        case 1:
            cell.textLabel?.text = "X Is Close"
            cell.switchElement.isOn = notifications.linkOnPage
        case 2:
            cell.textLabel?.text = "X Missed The Link"
            cell.switchElement.isOn = notifications.missedLink
        case 3:
            cell.textLabel?.text = "X Is On USA"
            cell.switchElement.isOn = notifications.isOnUSA
        case 4:
            cell.textLabel?.text = "X Is On The Same Page"
            cell.switchElement.isOn = notifications.isOnSamePage
        default:
            fatalError()
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "X indicates player name"
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
