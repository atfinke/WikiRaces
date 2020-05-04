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

//swiftlint:disable:next type_body_length
final internal class ResultsViewController: CenteredTableViewController {

    // MARK: - Types -

    enum ListenerUpdate {
        case readyButtonPressed
        case quit
    }

    // MARK: - Properties -

    var listenerUpdate: ((ListenerUpdate) -> Void)?
    var historyViewController: HistoryViewController?

    var quitAlertController: UIAlertController?
    var addPlayersViewController: UIViewController?

    var addPlayersBarButtonItem: UIBarButtonItem?
    var shareResultsBarButtonItem: UIBarButtonItem?

    var isAnimatingToPointsStandings = false
    var isPulsingReadyButton = false
    var hasAnimatedToPointsStandings = false

    let resultRenderer = ResultRenderer()
    var resultImage: UIImage? {
        didSet {
            updatedResultsImage()
        }
    }

    // MARK: - Game States -

    var localPlayer: WKRPlayer?

    var isPlayerHost = false {
        didSet {
            if isPlayerHost && addPlayersViewController != nil {
                addPlayersBarButtonItem?.isEnabled = false
            } else if let button = shareResultsBarButtonItem {
                navigationItem.leftBarButtonItems = [button]
            } else {
                navigationItem.leftBarButtonItems = nil
            }
        }
    }

    var state: WKRGameState = .results {
        didSet {
            updatedState(oldState: oldValue)
        }
    }

    var readyStates: WKRReadyStates? {
        didSet {
            if state == .hostResults {
                updateTableViewForNewReadyStates()
            }
        }
    }

    var resultsInfo: WKRResultsInfo? {
        didSet {
            updateTableView(oldValue)
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

        becomeFirstResponder()

        registerTableView(for: self)
        overlayButtonTitle = "Ready up"

        guideLabel.text = "TAP PLAYER TO VIEW HISTORY"
        descriptionLabel.text = "WAITING FOR PLAYERS TO FINISH"

        tableView.isUserInteractionEnabled = true
        tableView.register(ResultsTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.estimatedRowHeight = 150
        tableView.rowHeight = UITableView.automaticDimension

        let shareResultsBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action,
                                                        target: self,
                                                        action: #selector(shareResultsBarButtonItemPressed(_:)))
        shareResultsBarButtonItem.isEnabled = false
        let addPlayersBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                  target: self,
                                                  action: #selector(addPlayersBarButtonItemPressed))
        addPlayersBarButtonItem.isEnabled = false

        var items = [shareResultsBarButtonItem]
        if isPlayerHost && addPlayersViewController != nil {
            items.append(addPlayersBarButtonItem)
        }
        navigationItem.leftBarButtonItems = items

        self.shareResultsBarButtonItem = shareResultsBarButtonItem
        self.addPlayersBarButtonItem = addPlayersBarButtonItem

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop,
                                                            target: self,
                                                            action: #selector(doneButtonPressed))
    }

    // MARK: - Game Updates -

    private func updatedState(oldState: WKRGameState) {
        if state == .results || state == .hostResults {
            title = "RESULTS"
            tableView.isUserInteractionEnabled = true
            updateTableView()
        } else {
            tableView.isUserInteractionEnabled = false

            if let hack = presentedViewController, hack.title == "Hack" {
                hack.dismiss(animated: true) { [weak self] in
                    self?.dismiss(animated: false, completion: nil)
                }
            } else if presentedViewController != nil {
                dismiss(animated: true, completion: nil)
            }

            if oldState != .points {

                let fadeAnimation = CATransition()
                fadeAnimation.duration = WKRAnimationDurationConstants.resultsTableFlash / 4
                fadeAnimation.type = .fade

                let navLayer = navigationController?.navigationBar.layer
                navLayer?.add(fadeAnimation, forKey: "fadeOut")
                navigationItem.title = ""

                isAnimatingToPointsStandings = true
                UIView.animateFlash(withDuration: WKRAnimationDurationConstants.resultsTableFlash,
                                    items: [tableView],
                                    whenHidden: {
                                        self.tableView.reloadData()
                                        navLayer?.add(fadeAnimation, forKey: "fadeIn")
                                        self.navigationItem.title = "STANDINGS"

                }, completion: {
                    self.isAnimatingToPointsStandings = false
                    self.hasAnimatedToPointsStandings = true
                })

                if isPlayerHost, let results = resultsInfo {
                    DispatchQueue.global().async {
                        PlayerDatabaseMetrics.shared.record(results: results)
                    }
                }
            }

            if !isAnimatingToPointsStandings && hasAnimatedToPointsStandings {
                tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            }

            UIView.animate(withDuration: 0.5, animations: {
                self.guideLabel.alpha = 0.0
                self.descriptionLabel.alpha = 0.0
            })
        }
    }

    private func updatedTime(oldTime: Int) {
        tableView.isUserInteractionEnabled = true
        if oldTime == 100 {
            UIView.animateFlash(withDuration: 0.75,
                                items: [guideLabel, descriptionLabel],
                                whenHidden: {
                self.guideLabel.text = "TAP PLAYER TO VIEW HISTORY"
                self.descriptionLabel.text = "NEXT ROUND STARTS IN " + self.timeRemaining.description + " S"
            }, completion: nil)

            guard let localPlayer = localPlayer else { return }
            var resultsPlayer: WKRPlayer?

            for index in 0..<(resultsInfo?.playerCount ?? 0) {
                let player = resultsInfo?.raceRankingsPlayer(at: index)
                if localPlayer == player {
                    resultsPlayer = player
                }
            }

            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }),
                let results = self.resultsInfo,
                let player = resultsPlayer,
                player.raceHistory != nil else { return }

            resultRenderer.render(with: results, for: player, on: window) { [weak self] image in
                self?.resultImage = image
                self?.shareResultsBarButtonItem?.isEnabled = true
            }
        } else {
            descriptionLabel.text = "NEXT ROUND STARTS IN " + timeRemaining.description + " S"
        }
    }

    // MARK: - Helpers -

    private func updatedResultsImage() {
        guard let image = resultImage, UserDefaults.standard.bool(forKey: "force_save_result_image") else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        PlayerAnonymousMetrics.log(event: .automaticResultsImageSave)
    }

    private func updateTableViewForNewReadyStates() {
        guard !(state == .points && !hasAnimatedToPointsStandings) else {
            return
        }

        guard !isAnimatingToPointsStandings,
            let resultsInfo = resultsInfo,
            let readyStates = readyStates else {
                return
        }

        var isAnotherPlayerReady = false
        var isLocalPlayerReady = false
        for index in 0..<resultsInfo.playerCount {
            let player = resultsInfo.raceRankingsPlayer(at: index)
            guard let cell = tableView.cellForRow(at: IndexPath(row: index)) as? ResultsTableViewCell else {
                tableView.reloadData()
                return
            }
            let isPlayerReady = readyStates.isPlayerReady(player)
            cell.isShowingCheckmark = isPlayerReady

            if player == localPlayer {
                isLocalPlayerReady = isPlayerReady
            } else if isPlayerReady {
                isAnotherPlayerReady = true
            }
        }

        if isAnotherPlayerReady && !isLocalPlayerReady && !isAnimatingToPointsStandings {
            isAnimatingToPointsStandings = true
            animateButtonLabel()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func animateButtonLabel() {
        guard viewIfLoaded?.window != nil,
            let label = overlayButton.titleLabel else {
            return
        }
        UIView.animateFlash(withDuration: 2,
                            toAlpha: 0.25,
                            items: [label],
                            whenHidden: nil,
                            completion: {
            self.animateButtonLabel()
        })
    }

    private func updateTableView(_ oldResultsInfo: WKRResultsInfo? = nil) {
        guard !(state == .points && !hasAnimatedToPointsStandings) else {
            return
        }
        guard !isAnimatingToPointsStandings else { return }
        guard let oldInfo = oldResultsInfo,
            let newInfo = resultsInfo,
            oldInfo.playerCount == newInfo.playerCount else {
            tableView.reloadSections(IndexSet(integer: 0), with: .fade)
            return
        }

        let previousPlayerOrder = oldInfo.raceResultsPlayerProfileOrder()
        let newPlayerOrder = newInfo.raceResultsPlayerProfileOrder()

        var newIndexes = (0..<oldInfo.playerCount).map { $0 }
        for (index, player) in previousPlayerOrder.enumerated() {
            guard let newIndex = newPlayerOrder.firstIndex(of: player) else {
                // unexpected state
                tableView.reloadData()
                return
            }
            newIndexes[index] = newIndex
        }

        var moves = [Int: Int]()
        for (oldIndex, newIndex) in newIndexes.enumerated() {
            moves[oldIndex] = newIndex
        }

        let keys = moves.sorted { (lhs, rhs) -> Bool in
            return lhs.value > rhs.value
        }

        tableView.performBatchUpdates({
            for (oldIndex, newIndex) in keys {
                guard let cell = tableView.cellForRow(at: IndexPath(row: oldIndex)) as? ResultsTableViewCell else {
                    tableView.reloadSections(IndexSet(integer: 0), with: .fade)
                    return
                }

                cell.updateResults(for: newInfo.raceRankingsPlayer(at: newIndex), animated: true)
                if newIndex < oldIndex {
                    tableView.moveRow(at: IndexPath(row: oldIndex),
                                      to: IndexPath(row: newIndex))
                }
            }
        }, completion: nil)
    }

    func updateHistoryController() {
        guard let player = historyViewController?.player,
            let updatedPlayer = resultsInfo?.updatedPlayer(for: player) else {
                return
        }
        historyViewController?.player = updatedPlayer
    }

    func showReadyUpButton(_ showReady: Bool) {
        addPlayersBarButtonItem?.isEnabled = showReady
        if !showReady {
            shareResultsBarButtonItem?.isEnabled = showReady
        }

        isOverlayButtonHidden = !showReady
        UIView.animate(withDuration: WKRAnimationDurationConstants.resultsOverlayButtonToggle) {
            self.view.layoutIfNeeded()
        }
    }

    override func overlayButtonPressed() {
        PlayerAnonymousMetrics.log(event: .userAction(#function))

        UISelectionFeedbackGenerator().selectionChanged()

        addPlayersBarButtonItem?.isEnabled = false
        shareResultsBarButtonItem?.isEnabled = false

        listenerUpdate?(.readyButtonPressed)
        isOverlayButtonHidden = true

        UIView.animate(withDuration: WKRAnimationDurationConstants.resultsOverlayButtonToggle) {
            self.view.layoutIfNeeded()
        }

        PlayerAnonymousMetrics.log(event: .pressedReadyButton, attributes: ["Time": timeRemaining as Any])
    }

}
