//
//  PreRaceViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import GameKit
import SwiftUI
import WKRKit
import WKRUIKit
import os.log

class PreRaceViewController: HostingViewController {
    
    // MARK: - Types -

    enum Destination {
        case hostCustom, joinCustom(raceCode: String), joinStandard(invite: GKInvite?)
    }
    
    // MARK: - Properties -
    
    let destination: Destination
    var model = PreRaceContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: PreRaceContentView(model: model, cancel: { [weak self] in
            self?.cancel()
        }, disclaimerButton: {
            UIApplication.shared.open(WKRKitConstants.current.manageGameCenterLink)
        }))
    
    // MARK: - Initalization -
    
    init(destination: Destination) {
        self.destination = destination
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)
    }
    
    func cancel() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.view.alpha = 0
        }, completion: { [weak self] _ in
            self?.navigationController?.popToRootViewController(animated: false)
        })
    }
}
