//
//  StatsCountsViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

class StatsCountsViewController: UITableViewController {

    // MARK: - Properties -

    var counts: [(String, Int)] = [] {
        didSet {
            assert(Thread.isMainThread)
            tableView.reloadData()
        }
    }
    // MARK: - Initalization -

    init(title: String) {
        super.init(style: .insetGrouped)
        self.title = title.uppercased()
        tableView.allowsSelection = false
        tableView.cellLayoutMarginsFollowReadableWidth = true
        tableView.rowHeight = UITableView.automaticDimension
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UITableViewDataSource -

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return max(1, counts.count)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        if counts.isEmpty {
            cell.textLabel?.text = "No Stats Yet"
            cell.textLabel?.textColor = .secondaryLabel
        } else {
            let item = counts[indexPath.row]
            cell.textLabel?.text = item.0
            cell.detailTextLabel?.text = item.1.description + "x"
        }
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        cell.textLabel?.sizeToFit()
        
        cell.textLabel?.font = UIFont.tableViewCellTitle()
        cell.detailTextLabel?.font = UIFont.tableViewCellDetail()
        cell.detailTextLabel?.setContentCompressionResistancePriority(.required, for: .horizontal)
        return cell
    }

}
