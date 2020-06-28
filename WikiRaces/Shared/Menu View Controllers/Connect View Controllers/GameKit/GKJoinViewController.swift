//
//  GKJoinViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/25/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import GameKit
import SwiftUI

import WKRKit
import WKRUIKit

#if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
import FirebasePerformance
#endif

final class GKJoinViewController: GKConnectViewController {

    // MARK: - Properties -

    let raceCode: String?
    
    let isPublicRace: Bool
    var publicRaceHostAlias: String?
    
    var model = LoadingContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: LoadingContentView(model: model, cancel: { [weak self] in
            self?.cancelMatch()
        }))
    
    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
    var findTrace: Trace?
    #endif
    
    // MARK: - Initalization -
    
    init(raceCode: String?) {
        self.raceCode = raceCode
        self.isPublicRace = raceCode == nil
        super.init(isPlayerHost: false)
        
        findMatch()
    }
   
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - View Life Cycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentViewHosting.view.alpha = 0
        configure(hostingView: contentViewHosting.view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.contentViewHosting.view.alpha = 1
        }
    }
    
    // MARK: - Helpers -
    
    func findMatch() {
        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
        // TODO: fix
//        let type = raceCode == nil ? "Public" : "Private"
//        findTrace = Performance.startTrace(name: "Global Race Find Trace - " + type)
        #endif
        
        DispatchQueue.main.async {
            if self.raceCode == nil {
                self.model.title = "searching for race"
            } else {
                self.model.title = "joining race"
            }
        }
        
        GKMatchmaker.shared().findMatch(for: GKMatchRequest.joinRequest(raceCode: raceCode)) { [weak self] match, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    print(error)
                    let title = self.raceCode == nil ? "Unable To Find Race" : "Unable To Join Race"
                    self.showError(title: title, message: "Please try again later.")
                    self.model.title = "MATCHMAKING ISSUE"
                    self.model.activityOpacity = 0
                } else if let match = match {
                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    self.findTrace?.stop()
                    #endif
                    self.match = match
                    match.delegate = self
                    
                    if self.isPublicRace {
                        self.publicRaceDetermineHost(match: match)
                    }
                } else {
                    fatalError()
                }
            }
        }
    }
}
