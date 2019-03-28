//
//  DebugInfoTableViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 9/15/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import UIKit

class DebugInfoTableViewController: UITableViewController {

    // MARK: - Properties

    var info = [(key: String, value: Any)]()

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 100
        tableView.register(DebugInfoTableViewCell.self,
                           forCellReuseIdentifier: DebugInfoTableViewCell.reuseIdentifier)

        navigationController?.navigationBar.barStyle = UIBarStyle.wkrStyle
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                            target: self,
                                                            action: #selector(share(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                            target: self,
                                                            action: #selector(done))
    }

    // MARK: - Actions

    @objc
    func done() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func share(_ sender: UIBarButtonItem) {
        var string = "WikiRaces Debug:\n"
        for (key, value) in info {
            string += "\n\nKey: \(key)\nValue:\n\(String(describing: value))"
        }
        let activityViewController = UIActivityViewController(activityItems: [string], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return info.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DebugInfoTableViewCell.reuseIdentifier,
                                                       for: indexPath) as? DebugInfoTableViewCell else {
                                                        fatalError()
        }

        let preference = info[indexPath.row]
        cell.textLabel?.text = preference.key
        cell.detailTextLabel?.text = String(describing: preference.value)

        return cell
    }

    // UITableViewDelegate

    override func tableView(_ tableView: UITableView,
                            canPerformAction action: Selector,
                            forRowAt indexPath: IndexPath,
                            withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    override func tableView(_ tableView: UITableView,
                            performAction action: Selector,
                            forRowAt indexPath: IndexPath,
                            withSender sender: Any?) {
        guard action == #selector(copy(_:)),
            let cell = tableView.cellForRow(at: indexPath),
            let text = cell.textLabel?.text,
            let detail = cell.detailTextLabel?.text else { return }

        let string = "Key: \(text)\nValue:\n\(detail)"
        UIPasteboard.general.string = string
    }

    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

}
