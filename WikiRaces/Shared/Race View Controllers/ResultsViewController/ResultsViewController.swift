//
//  ResultsViewController.swift
//  WikiRaces
//
//  Created by Andrew Finke on 8/5/17.
//  Copyright © 2017 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit
import WKRUIKit

import SwiftUI

final internal class ResultsViewController: VisualEffectViewController {

    // MARK: - Types -

    enum ListenerUpdate {
        case readyButtonPressed
        case quit
    }

    // MARK: - Properties -

    let model = ResultsContentViewModel()
    lazy var contentViewHosting = UIHostingController(
        rootView: ResultsContentView(
            model: model,
            readyUpButtonPressed: { [weak self] in
                self?.readyUpButtonPressed()
            }, tappedPlayerID: { [weak self] playerID in
                self?.tapped(playerID: playerID)
        }))

    var listenerUpdate: ((ListenerUpdate) -> Void)?
    var historyViewController: HistoryViewController?

    var quitAlertController: UIAlertController?
    var isPulsingReadyButton = false

    let resultRenderer = ResultRenderer()
    var resultImage: UIImage? {
        didSet {
            updatedResultsImage()
        }
    }

    // MARK: - Game States -

    var localPlayer: WKRPlayer?
    var isPlayerHost = false

    var state: WKRGameState = .results {
        didSet {
            updatedState(oldState: oldValue)
            model.update(to: resultsInfo, readyStates: readyStates, for: state)
        }
    }

    var readyStates: WKRReadyStates? {
        didSet {
            if state == .hostResults {
                model.update(to: resultsInfo, readyStates: readyStates, for: state)
                checkIfOtherPlayersReady()
            }
        }
    }

    var resultsInfo: WKRResultsInfo? {
        didSet {
            model.update(to: resultsInfo, readyStates: readyStates, for: state)
            updateHistoryController()
        }
    }

    var timeRemaining: Int = 100 {
        didSet {
            updatedTime(oldTime: oldValue)
        }
    }

    // MARK: - View Life Cycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "RESULTS"

        addChild(contentViewHosting)
        configure(hostingView: contentViewHosting.view)
        contentViewHosting.didMove(toParent: self)

        model.footerTopText = "TAP PLAYER TO VIEW HISTORY"
        model.footerBottomText = "WAITING FOR PLAYERS TO FINISH"

        let shareResultsBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                        target: self,
                                                        action: #selector(shareResultsBarButtonItemPressed(_:)))
        shareResultsBarButtonItem.isEnabled = false
        navigationItem.leftBarButtonItem = shareResultsBarButtonItem

        navigationItem.rightBarButtonItem = WKRUIBarButtonItem(
            systemName: "xmark",
            target: self,
            action: #selector(doneButtonPressed))

        becomeFirstResponder()
    }

    // MARK: - Game Updates -

    private func updatedState(oldState: WKRGameState) {
        guard state == .points && oldState != .points else {
            return
        }

        model.footerOpacity = 0

        if isPlayerHost, let results = resultsInfo {
            DispatchQueue.global().async {
                PlayerDatabaseMetrics.shared.record(results: results)
            }
        }

        if let hack = presentedViewController, hack.title == "Hack" {
            hack.dismiss(animated: true) { [weak self] in
                self?.dismiss(animated: false, completion: nil)
            }
        } else if presentedViewController != nil {
            dismiss(animated: true, completion: nil)
        }
    }

    private func updatedTime(oldTime: Int) {
        if oldTime == 100 {
            model.footerOpacity = 0
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.model.footerTopText = "TAP PLAYER TO VIEW HISTORY"
                self.model.footerBottomText = "NEXT ROUND STARTS IN " + self.timeRemaining.description + " S"
            }

            guard let localPlayer = localPlayer else { return }
            let resultsPlayer = resultsInfo?.raceRankings().first(where: { $0 == localPlayer })

            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                let results = self.resultsInfo,
                let player = resultsPlayer,
                player.raceHistory != nil else { return }

            resultRenderer.render(with: results, for: player, on: window) { [weak self] image in
                self?.resultImage = image
                self?.navigationItem.leftBarButtonItem?.isEnabled = true
            }
        } else {
            model.footerBottomText = "NEXT ROUND STARTS IN " + timeRemaining.description + " S"
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                guard self.state != .points else { return }
                self.model.footerOpacity = 1
            }
        }
    }

    // MARK: - Helpers -

    private func updatedResultsImage() {
        guard let image = resultImage, Defaults.shouldAutoSaveResultImage else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        PlayerAnonymousMetrics.log(event: .automaticResultsImageSave)
    }

    private func checkIfOtherPlayersReady() {
        guard state == .hostResults,
              !isPulsingReadyButton,
            let resultsInfo = resultsInfo,
            let readyStates = readyStates else {
                return
        }

        var isAnotherPlayerReady = false
        var isLocalPlayerReady = false
        for player in resultsInfo.raceRankings() where readyStates.isPlayerReady(player) {
            if player == localPlayer {
                isLocalPlayerReady = true
            } else {
                isAnotherPlayerReady = true
            }
        }

        if isAnotherPlayerReady && !isLocalPlayerReady && !isPulsingReadyButton {
            isPulsingReadyButton = true
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            model.startPulsingButton()
        }
    }

    func updateHistoryController() {
        guard let player = historyViewController?.player,
            let updatedPlayer = resultsInfo?.updatedPlayer(for: player) else {
                return
        }
        historyViewController?.player = updatedPlayer
    }

    func showReadyUpButton(_ showReady: Bool) {
        if !showReady {
            navigationItem.leftBarButtonItem?.isEnabled = showReady
        }
        model.buttonEnabled = showReady
    }

    func readyUpButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        navigationItem.leftBarButtonItem?.isEnabled = false
        listenerUpdate?(.readyButtonPressed)
        model.buttonEnabled = false

        PlayerAnonymousMetrics.log(event: .pressedReadyButton, attributes: ["Time": timeRemaining as Any])
    }

}
