//
//  CustomRaceOtherController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

final class CustomRaceOtherController: UITableViewController {

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

    var other: RaceSettings.Other {
        didSet {
            didUpdate?(other)
        }
    }
    var didUpdate: ((RaceSettings.Other) -> Void)?

    // MARK: - Initalization -

    init(other: RaceSettings.Other) {
        self.other = other
        super.init(style: .grouped)
        title = "Other"
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
        cell.switchElement.tag = indexPath.row
        cell.switchElement.addTarget(self, action: #selector(switchChanged(updatedSwitch:)), for: .valueChanged)

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Help Enabled"
            cell.switchElement.isOn = other.isHelpEnabled
        default:
            fatalError()
        }

        return cell
    }

    // MARK: - Helpers -

    @objc
    func switchChanged(updatedSwitch: UISwitch) {
        other = RaceSettings.Other(isHelpEnabled: updatedSwitch.tag == 0 ? updatedSwitch.isOn : other.isHelpEnabled)
    }

}
