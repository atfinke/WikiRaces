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
import os.log

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
            self?.isShowingError = true
            self?.cancelMatch()
        }, disclaimerButton: nil))

    // MARK: - Initalization -

    init(raceCode: String?) {
        self.raceCode = raceCode
        self.isPublicRace = raceCode == nil
        super.init(isPlayerHost: false)

        os_log("%{public}s", log: .gameKit, type: .info, #function)

        findMatch()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()
        configure(hostingView: contentViewHosting.view)
    }

    // MARK: - Helpers -

    func findMatch() {
        os_log("%{public}s: race code: %{public}s", log: .gameKit, type: .info, #function, raceCode ?? "-")
        #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                let type = raceCode == nil ? "Public" : "Private"
               let findTrace = Performance.startTrace(name: "Global Race Find Trace - " + type)
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
                    os_log("%{public}s: result: error: %{public}s", log: .gameKit, type: .error, #function, error.localizedDescription)

                    let bannerTitle: String
                    let interfaceTitle: String
                    if self.isPublicRace {
                        bannerTitle = "Unable To Find Race"
                        interfaceTitle = "NO OPEN RACES"
                    } else {
                        bannerTitle = "Unable To Join Race"
                        interfaceTitle = "MATCHMAKING ISSUE"
                    }
                    self.showError(title: bannerTitle, message: "Please try again later.")
                    self.model.title = interfaceTitle
                    self.model.activityOpacity = 0
                } else if let match = match {
                    os_log("%{public}s: found match", log: .gameKit, type: .info, #function)

                    #if !MULTIWINDOWDEBUG && !targetEnvironment(macCatalyst)
                    findTrace?.stop()
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
