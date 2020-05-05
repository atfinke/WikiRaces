//
//  CustomRaceOtherController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final class CustomRaceOtherController: UITableViewController {

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

    var other: WKRGameSettings.Other {
        didSet {
            didUpdate?(other)
        }
    }
    var didUpdate: ((WKRGameSettings.Other) -> Void)?

    // MARK: - Initalization -

    init(other: WKRGameSettings.Other) {
        self.other = other
        super.init(style: .grouped)
        title = "Other".uppercased()
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
        return 1
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
            cell.textLabel?.text = "Help Enabled"
            cell.toggle.isOn = other.isHelpEnabled
        default:
            fatalError()
        }

        return cell
    }

    // MARK: - Helpers -

    @objc
    func switchChanged(updatedSwitch: UISwitch) {
        other = WKRGameSettings.Other(isHelpEnabled: updatedSwitch.tag == 0 ? updatedSwitch.isOn : other.isHelpEnabled)
    }

}
