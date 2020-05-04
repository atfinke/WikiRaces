//
//  CustomRaceViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final class CustomRaceViewController: UITableViewController {

    // MARK: - Types -

    enum Setting: String, CaseIterable {
        case startPage = "Start Page"
        case endPage = "End Page"
        case bannedPages = "Banned Pages"
        case notifications = "Player Messages"
        case points, timing, other
    }

    // MARK: - Properties -

    private let settingOptions = Setting.allCases
    var allCustomPages = [WKRPage]()
    let settings: WKRGameSettings

    // MARK: - Initalization -

    init(settings: WKRGameSettings) {
        self.settings = settings
        super.init(style: .grouped)
        title = "Customize Race"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? settingOptions.count : 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 1 {
            cell.textLabel?.text = "Reset to Default"
            cell.textLabel?.textColor = .systemRed
            return cell
        }

        let setting = settingOptions[indexPath.row]
        cell.textLabel?.text = setting.rawValue.capitalized
        cell.detailTextLabel?.text = value(for: setting)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate -

    //swiftlint:disable:next function_body_length
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !PlusStore.shared.isPlus {
            PlayerAnonymousMetrics.log(event: .forcedIntoStoreFromCustomize)
            let controller = PlusViewController()
            controller.modalPresentationStyle = .overCurrentContext
            present(controller, animated: false, completion: nil)
            tableView.deselectRow(at: indexPath, animated: true)
            return
        } else if indexPath.section == 1 {
            settings.reset()
            tableView.reloadData()
            return
        }

        let setting = settingOptions[indexPath.row]
        switch setting {
        case .startPage:
            let controller = CustomRacePageViewController(
                pageType: .start,
                customPages: allCustomPages,
                selectedOption: settings.startPage)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateStartPage = { page in
                self.settings.startPage = page
                self.allCustomPages = controller.customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .endPage:
            let controller = CustomRacePageViewController(
            pageType: .end,
            customPages: allCustomPages,
            selectedOption: settings.endPage)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateEndPage = { page in
                self.settings.endPage = page
                self.allCustomPages = controller.customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .bannedPages:
            let controller = CustomRacePageViewController(
            pageType: .banned,
            customPages: allCustomPages,
            selectedOption: settings.bannedPages)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateBannedPages = { pages in
                self.settings.bannedPages = pages
                self.allCustomPages = controller.customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .notifications:
            let controller = CustomRaceNotificationsController(notifications: settings.notifications)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdate = { notifications in
                self.settings.notifications = notifications
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .points:
            let controller = CustomRaceNumericalViewController(settingsType: .points, currentValue: settings.points)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdatePoints = { points in
                self.settings.points = points
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .timing:
            let controller = CustomRaceNumericalViewController(settingsType: .timing, currentValue: settings.timing)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateTiming = { timing in
                self.settings.timing = timing
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .other:
            let controller = CustomRaceOtherController(other: settings.other)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdate = { other in
                self.settings.other = other
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Helpers -

    //swiftlint:disable:next cyclomatic_complexity
    private func value(for setting: Setting) -> String {
        switch setting {
        case .startPage:
            switch settings.startPage {
            case .random:
                return "Random"
            case .custom(let page):
                return page.path
            }
        case .endPage:
            switch settings.endPage {
            case .curatedVoting:
                return "Curated + Voting"
            case .randomVoting:
                return "Random + Voting"
            case .custom(let page):
                return page.path
            }
        case .bannedPages:
            if settings.bannedPages.count == 1, case .portal = settings.bannedPages[0] {
                return "Standard"
            } else {
                return "Custom"
            }
        case .notifications:
            if settings.notifications.isStandard {
                return "All"
            } else {
                return "Custom"
            }
        case .points:
            if settings.points.isStandard {
                return "Standard"
            } else {
                return "Custom"
            }
        case .timing:
            if settings.timing.isStandard {
                return "Standard"
            } else {
                return "Custom"
            }
        case .other:
            return ""
        }
    }
}
