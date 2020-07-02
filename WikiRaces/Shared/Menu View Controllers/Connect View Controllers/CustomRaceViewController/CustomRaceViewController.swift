//
//  CustomRaceViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

final class CustomRaceViewController: CustomRaceController {

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
    let settings: WKRGameSettings

    var allCustomPages: [WKRPage]
    var finalPagesCallback: ([WKRPage]) -> Void

    // MARK: - Initalization -

    init(settings: WKRGameSettings, pages: [WKRPage], finalPages: @escaping (([WKRPage]) -> Void)) {
        self.settings = settings
        self.allCustomPages = pages
        self.finalPagesCallback = finalPages
        super.init(style: .grouped)
        title = "Customize Race".uppercased()

        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(doneButtonPressed))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        finalPagesCallback(allCustomPages)
    }

    // MARK: - UITableViewDataSource -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return settingOptions.count
        } else if section == 1 {
            return 1
        } else {
            return 3
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 2 ? "Presets" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if indexPath.section == 1 {
            cell.textLabel?.text = "Reset to Default"
            cell.textLabel?.textColor = .systemRed
            return cell
        } else if indexPath.section == 2 {
            if indexPath.row == 0 {
                cell.textLabel?.text = "First to Magic Kingdom"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "No USA"
            } else if indexPath.row == 2 {
                cell.textLabel?.text = "Rapid random voting"
            }
            return cell
        }

        let setting = settingOptions[indexPath.row]
        cell.textLabel?.text = setting.rawValue.capitalized
        cell.detailTextLabel?.text = value(for: setting)
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate -

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
        } else if indexPath.section == 2 {
            settings.reset()
            if indexPath.row == 0 {
                guard let url = URL(string: "https://en.m.wikipedia.org/wiki/Magic_Kingdom") else { fatalError() }
                let page = WKRPage(title: "Magic Kingdom", url: url)
                settings.endPage = .custom(page)
            } else if indexPath.row == 1 {
                guard let url = URL(string: "https://en.m.wikipedia.org/wiki/United_States") else { fatalError() }
                let page = WKRPage(title: "United States", url: url)
                settings.bannedPages = [.portal, .custom(page)]
            } else if indexPath.row == 2 {
                settings.timing = WKRGameSettings.Timing(votingTime: 5, resultsTime: 60)
                settings.endPage = .randomVoting
            }
            tableView.reloadData()
            return
        }

        let setting = settingOptions[indexPath.row]
        switch setting {
        case .startPage:
            let controller = CustomRacePageViewController(
                pageType: .start,
                customPages: allCustomPages,
                settings: settings)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateStartPage = { [weak self] page, customPages in
                guard let self = self else { return }
                self.settings.startPage = page
                self.allCustomPages = customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .endPage:
            let controller = CustomRacePageViewController(
                pageType: .end,
                customPages: allCustomPages,
                settings: settings)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateEndPage = { [weak self] page, customPages in
                guard let self = self else { return }
                self.settings.endPage = page
                self.allCustomPages = customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .bannedPages:
            let controller = CustomRacePageViewController(
                pageType: .banned,
                customPages: allCustomPages,
                settings: settings)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateBannedPages = { [weak self] pages, customPages in
                guard let self = self else { return }
                self.settings.bannedPages = pages
                self.allCustomPages = customPages
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .notifications:
            let controller = CustomRaceNotificationsController(notifications: settings.notifications)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdate = { [weak self] notifications in
                guard let self = self else { return }
                self.settings.notifications = notifications
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .points:
            let controller = CustomRaceNumericalViewController(settingsType: .points, currentValue: settings.points)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdatePoints = { [weak self] points in
                guard let self = self else { return }
                self.settings.points = points
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .timing:
            let controller = CustomRaceNumericalViewController(settingsType: .timing, currentValue: settings.timing)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdateTiming = { [weak self] timing in
                guard let self = self else { return }
                self.settings.timing = timing
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        case .other:
            let controller = CustomRaceOtherController(other: settings.other)
            navigationController?.pushViewController(controller, animated: true)
            controller.didUpdate = { [weak self] other in
                guard let self = self else { return }
                self.settings.other = other
                DispatchQueue.main.async {
                    tableView.reloadData()
                }
            }
        }
    }

    // MARK: - Helpers -

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

    @objc func doneButtonPressed() {
        dismiss(animated: true, completion: nil)
    }
}
