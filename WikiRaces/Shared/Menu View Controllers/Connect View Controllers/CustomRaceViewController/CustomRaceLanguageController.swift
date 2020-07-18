//
//  CustomRaceLanguageController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 7/17/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

final class CustomRaceLanguageController: CustomRaceController {

    // MARK: - Types -

    private class Cell: UITableViewCell {

        // MARK: - Properties -

        let textField = UITextField()
        static let reuseIdentifier = "reuseIdentifier"

        // MARK: - Initalization -

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            textField.textAlignment = .right
            contentView.addSubview(textField)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        // MARK: - View Life Cycle -

        override func layoutSubviews() {
            super.layoutSubviews()
            textField.frame = CGRect(origin: .zero, size: CGSize(width: 80, height: contentView.frame.height))
            textField.center = CGPoint(
                x: contentView.frame.width - contentView.layoutMargins.right - textField.frame.width / 2,
                y: contentView.frame.height / 2)
        }
    }

    // MARK: - Properties -

    var language: WKRGameSettings.Language {
        didSet {
            didUpdate?(language)
        }
    }
    var didUpdate: ((WKRGameSettings.Language) -> Void)?
    private var textField: UITextField?

    // MARK: - Initalization -

    init(language: WKRGameSettings.Language) {
        self.language = language
        super.init(style: .grouped)
        title = "Language".uppercased()
        tableView.allowsSelection = false
        tableView.register(Cell.self, forCellReuseIdentifier: Cell.reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let text = textField?.text?.lowercased(), text != language.code {
            language = WKRGameSettings.Language(code: text)
        }
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
        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Language Code"
            cell.textField.text = language.code.lowercased()
            textField = cell.textField
        default:
            fatalError()
        }

        return cell
    }

     override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            return """
            Changing the Wikipedia language is highly experimental and not fully tested.

            Some aspects of the game may not work as expected when using any language other than the standard English Wikipedia (“en”).
            """
        }

}
