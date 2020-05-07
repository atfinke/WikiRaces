//
//  CustomRaceController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/6/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit
import WKRUIKit

class CustomRaceController: UITableViewController {

    // MARK: - Initalization -

    override init(style: UITableView.Style) {
        super.init(style: style)
        navigationItem.leftBarButtonItem = WKRUIBarButtonItem(systemName: "chevron.left",
                                                              target: self,
                                                              action: #selector(back))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers -

    @objc func back() {
        navigationController?.popViewController(animated: true)
    }
}
