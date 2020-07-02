//
//  ResultsContentViewModel.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/24/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit
import WKRUIKit

class ResultsContentViewModel: ObservableObject {

    // MARK: - Types -

    struct Item: Identifiable, Equatable {
        var id: String { return player.id }
        let player: WKRUIPlayer

        let subtitle: String
        let title: String
        let detail: String
        let isRacing: Bool
        let isReady: Bool
    }

    // MARK: - Properties -

    @Published var items = [Item]()
    @Published var footerTopText: String = ""
    @Published var footerBottomText: String = ""
    @Published var footerOpacity: Double = 1.0

    @Published var buttonFlashOpacity: Double = 1
    @Published var buttonEnabled: Bool = false

    // MARK: - Helpers -

    func startPulsingButton() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.buttonEnabled else { return }
            DispatchQueue.main.async {
                self.buttonFlashOpacity = self.buttonFlashOpacity == 1 ? 0.5 : 1
            }
        }
    }

    func update(to results: WKRResultsInfo?, readyStates: WKRReadyStates?, for state: WKRGameState) {
        guard let results = results else {
            items = []
            return
        }

        var newItems = [Item]()

        if state == .points {
            for playerResult in results.sessionResults() {
                var subtitleString = positionString(for: playerResult.ranking)
                subtitleString += playerResult.isTied ? " (Tied)" : ""

                let pointsSuffix = playerResult.points == 1 ? "" : "s"
                let item = Item(
                    player: WKRUIPlayer(id: playerResult.profile.playerID),
                    subtitle: subtitleString,
                    title: playerResult.points.description + " Point" + pointsSuffix,
                    detail: "",
                    isRacing: false,
                    isReady: false)
                newItems.append(item)
            }
        } else {
            for (index, player) in results.raceRankings().enumerated() {
                if state == .results || state == .hostResults {
                    var subtitle: String = ""
                    var title: String = ""
                    var detail: String = "-"

                    if let history = player.raceHistory, let entry = history.entries.last {
                        title = entry.page.title ?? "-"
                        subtitle = player.state.text
                        if player.state == .foundPage, let duration = WKRDurationFormatter.string(for: history.duration) {
                            subtitle = positionString(for: index + 1)
                            detail = duration
                        } else if player.state == .racing {
                            subtitle = "Racing"
                        } else if player.state == .forcedEnd || player.state == .forfeited {
                            subtitle = "Did Not Finish"
                        }

                    } else {
                        subtitle = "-"
                        title = "-"
                        if player.state == .forcedEnd {
                            subtitle = "Did not finish"
                        } else if player.state == .quit {
                            subtitle = "Quit"
                        }
                    }

                    let item = Item(
                        player: WKRUIPlayer(id: player.profile.playerID),
                        subtitle: subtitle,
                        title: title,
                        detail: detail,
                        isRacing: player.state == .racing,
                        isReady: readyStates?.isPlayerReady(player) ?? false)
                    newItems.append(item)
                }
            }
        }
        items = newItems
    }

    private func positionString(for position: Int) -> String {
        if position == 1 {
            return "1st Place"
        } else if position == 2 {
            return "2nd Place"
        } else if position == 3 {
            return "3rd Place"
        } else if position < 21 {
            return "\(position)th Place"
        } else {
            fatalError()
        }
    }
}
