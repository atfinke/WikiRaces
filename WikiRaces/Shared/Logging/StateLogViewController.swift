//
//  StateLogViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 12/27/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit

internal class StateLogViewController: UIViewController {

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerMetrics.log(state: .didLoad, for: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PlayerMetrics.log(state: .willAppear, for: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        PlayerMetrics.log(state: .didAppear, for: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PlayerMetrics.log(state: .willDisappear, for: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PlayerMetrics.log(state: .didDisappear, for: self)
    }

}
