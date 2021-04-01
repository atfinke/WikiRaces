//
//  HostContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit
import WKRUIKit
import GameKit

private struct Header: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let state: HostContentViewModel.State
    let cancelAction: () -> Void
    let startMatch: () -> Void
    
    var body: some View {
        HStack {
            Button(action: cancelAction, label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22))
            })
            Spacer()
            Button(action: startMatch, label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 22))
            })
        }
        .foregroundColor(.wkrTextColor(for: colorScheme))
        .padding()
        .padding(.horizontal)
        .frame(height: 60)
    }
}

private struct PlayerImage: View {
    var body: some View {
        if Defaults.isFastlaneSnapshotInstance {
            WKRUIPlayerImageView(
                player: WKRPlayerProfile(name: "A", playerID: "A"),
                size: 100,
                effectSize: 5)
                .padding(.bottom, 20)
        } else {
            WKRUIPlayerImageView(
                player: WKRPlayerProfile(player: GKLocalPlayer.local),
                size: 100,
                effectSize: 2)
                .padding(.bottom, 20)
        }

        if !WKRUIPlayerImageManager.shared.isLocalPlayerImageFromGameCenter && !Defaults.isFastlaneSnapshotInstance {
            HStack {
                Spacer()
                Text("Set a custom racer photo\nin the Game Center settings")
                    .font(.system(size: 12, weight: .regular))
                    .multilineTextAlignment(.center)
                    .offset(y: -5)
                Spacer()
            }
        }
    }
}

private struct Mid: View {
    let raceCode: String?
    let isCustom: Bool
    let presentModal: (HostContentView.Modal) -> Void
    var body: some View {
        VStack {
            HostSectionView(
                header: "RACE CODE",
                title: (raceCode?.uppercased() ?? "-") + "  ", // ' ' prevents trimming??
                imageName: "square.and.arrow.up",
                disabled: raceCode == nil) {
                presentModal(.activity)
            }
            .padding(.vertical, 16)

            HostSectionView(
                header: "TYPE",
                title: isCustom ? "CUSTOM" : "STANDARD",
                imageName: "gear",
                disabled: false) {
                presentModal(.settings)
            }
        }.frame(width: 220)
    }
}

private struct Footer: View {
    let connectedPlayers: [WKRPlayerProfile]
    let state: HostContentViewModel.State
    let status: String
    var body: some View {
        HStack {
            Color.clear.frame(width: 1)
            ForEach(connectedPlayers) { player in
                WKRUIPlayerImageView(player: player, size: 44, effectSize: 3)
                    .padding(.all, 2)
            }
            .transition(.opacity)
            .scaleEffect(connectedPlayers.count < 6 ? 1 : 1.5 - 0.1 * CGFloat(connectedPlayers.count), anchor: .center)
            Color.clear.frame(width: 1)
        }
        .frame(maxHeight: 60)
        VStack {
            Text(status)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .transition(.opacity)
                .id(status)
            ActivityIndicatorView()
                .offset(x: 0, y: -5)
                .opacity(state == .soloRace ? 0 : 1)
        }
        .padding(.bottom, 20)
    }
}

struct HostContentView: View {

    // MARK: - Types -

    enum Modal {
        case activity, settings
    }

    // MARK: - Properties -

    @ObservedObject var model: HostContentViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let cancelAction: () -> Void
    let startMatch: () -> Void
    let presentModal: (Modal) -> Void

    // MARK: - Body -

    var body: some View {
        VStack {
            Header(state: model.state, cancelAction: cancelAction, startMatch: startMatch)
            Spacer()
            PlayerImage()
            Mid(raceCode: model.raceCode, isCustom: model.settings.isCustom, presentModal: presentModal)
            Color.clear.frame(height: 50)
            Spacer()
            Footer(connectedPlayers: model.connectedPlayers, state: model.state, status: model.status)
        }
        .animation(.spring())
    }
}
