//
//  StateLogTableViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 12/27/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

internal class StateLogTableViewController: UITableViewController {

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerAnalytics.log(state: .didLoad, for: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PlayerAnalytics.log(state: .willAppear, for: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PlayerAnalytics.log(state: .didAppear, for: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PlayerAnalytics.log(state: .willDisappear, for: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PlayerAnalytics.log(state: .didDisappear, for: self)
    }

}
