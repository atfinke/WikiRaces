//
//  CustomRaceNumericalViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/3/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final class CustomRaceNumericalViewController: UITableViewController {

    // MARK: - Types -

    private class Cell: UITableViewCell {

        // MARK: - Properties -

        static let reuseIdentifier = "reuseIdentifier"
        let stepper = UIStepper()
        let valueLabel: UILabel = {
            let label = UILabel()
            label.textAlignment = .right
            return label
        }()

        // MARK: - Initalization -

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            contentView.addSubview(stepper)
            contentView.addSubview(valueLabel)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - View Life Cycle -

        override func layoutSubviews() {
            super.layoutSubviews()

            stepper.center = CGPoint(
                x: contentView.frame.width - contentView.layoutMargins.right - stepper.frame.width / 2,
                y: contentView.frame.height / 2)

            let labelX = stepper.frame.minX - stepper.layoutMargins.left * 2
            valueLabel.frame = CGRect(
                x: labelX - 50,
                y: 0,
                width: 50,
                height: frame.height)
        }
    }

    enum SettingsType {
        case points, timing
    }

    // MARK: - Properties -

    var points: WKRGameSettings.Points? {
        didSet {
            guard let value = points else { fatalError() }
            didUpdatePoints?(value)
        }
    }
    var timing: WKRGameSettings.Timing? {
        didSet {
            guard let value = timing else { fatalError() }
            didUpdateTiming?(value)
        }
    }

    var didUpdatePoints: ((WKRGameSettings.Points) -> Void)?
    var didUpdateTiming: ((WKRGameSettings.Timing) -> Void)?

    let type: SettingsType

    // MARK: - Initalization -

    init(settingsType: SettingsType, currentValue: Any) {
        self.type = settingsType
        super.init(style: .grouped)

        switch type {
        case .points:
            guard let points = currentValue as? WKRGameSettings.Points else { fatalError() }
            self.points = points
            title = "Points".uppercased()
        case .timing:
            guard let timing = currentValue as? WKRGameSettings.Timing else { fatalError() }
            self.timing = timing
            title = "Timing".uppercased()
        }

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
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return type == .points ? "Bonus Points" : nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Cell.reuseIdentifier,
                                                       for: indexPath) as? Cell else {
            fatalError()
        }
        cell.stepper.tag = indexPath.row
        cell.stepper.addTarget(self, action: #selector(stepperChanged(stepper:)), for: .valueChanged)

        switch type {
        case .points:
            guard let points = points else { fatalError() }
            if indexPath.row == 0 {
                cell.textLabel?.text = "Award Interval"
                cell.stepper.minimumValue = 5
                cell.stepper.maximumValue = 360
                cell.stepper.stepValue = 5
                cell.stepper.value = points.bonusPointsInterval
                cell.valueLabel.text = Int(points.bonusPointsInterval).description + " S"
            } else {
                cell.textLabel?.text = "Award Amount"
                cell.stepper.minimumValue = 0
                cell.stepper.maximumValue = 20
                cell.stepper.stepValue = 1
                cell.stepper.value = Double(points.bonusPointReward)
                cell.valueLabel.text = points.bonusPointReward.description
            }
        case .timing:
            guard let timing = timing else { fatalError() }
            if indexPath.row == 0 {
                cell.textLabel?.text = "Voting Time"
                cell.stepper.minimumValue = 5
                cell.stepper.maximumValue = 120
                cell.stepper.stepValue = 1
                cell.stepper.value = Double(timing.votingTime)
                cell.valueLabel.text = timing.votingTime.description + " S"
            } else {
                cell.textLabel?.text = "Results Time"
                cell.stepper.minimumValue = 15
                cell.stepper.maximumValue = 360
                cell.stepper.stepValue = 5
                cell.stepper.value = Double(timing.resultsTime)
                cell.valueLabel.text = timing.resultsTime.description + " S"
            }
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if type == .points {
            let title = """
The award interval is the frequency at which bonus points are added to the total points awarded. If set to 60, then every 60 seconds, the total points awarded to the race winner will increase by the amount specified.

Stats Effect: Prevents improving points per race average and total number of races.
"""
            return title
        } else {
            return nil
        }
    }

    // MARK: - Helpers -

    @objc func stepperChanged(stepper: UIStepper) {
        let indexPath = IndexPath(row: stepper.tag, section: 0)
        guard let cell = tableView.cellForRow(at: indexPath) as? Cell else { fatalError() }

        switch type {
        case .points:
            guard let points = points else { fatalError() }
            if indexPath.row == 0 {
                self.points = WKRGameSettings.Points(
                    bonusPointReward: points.bonusPointReward,
                    bonusPointsInterval: stepper.value)
                cell.valueLabel.text = Int(stepper.value).description + " S"
            } else {
                self.points = WKRGameSettings.Points(
                    bonusPointReward: Int(stepper.value),
                    bonusPointsInterval: points.bonusPointsInterval)
                cell.valueLabel.text = Int(stepper.value).description
            }
        case .timing:
            guard let timing = timing else { fatalError() }
            if indexPath.row == 0 {
                self.timing = WKRGameSettings.Timing(
                    votingTime: Int(stepper.value),
                    resultsTime: timing.resultsTime)
                cell.valueLabel.text = Int(stepper.value).description + " S"
            } else {
                self.timing = WKRGameSettings.Timing(
                    votingTime: timing.votingTime,
                    resultsTime: Int(stepper.value))
                cell.valueLabel.text = Int(stepper.value).description + " S"
            }
        }
    }
}
