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
            HStack {
                Button(action: cancelAction, label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22))
                })
                .opacity(model.matchStarting ? 0.2 : 1)
                Spacer()
                if model.matchStarting {
                    ActivityIndicatorView()
                } else {
                    Button(action: startMatch, label: {
                        Image(systemName: "play.fill")
                            .font(.system(size: 22))
                    })
                }
            }
            .foregroundColor(.wkrTextColor(for: colorScheme))
            .padding()
            .padding(.horizontal)
            .frame(height: 60)
            .allowsHitTesting(!model.matchStarting)

            Spacer()
            WKRUIPlayerImageView(
                player: WKRUIPlayer(id: GKLocalPlayer.local.alias),
                size: 100,
                effectSize: 5)
                .padding(.bottom, 20)

            if !WKRUIPlayerImageManager.shared.isLocalPlayerImageSet {
                HStack {
                    Spacer()
                    Text("Set a custom racer photo\nin the Game Center settings")
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .multilineTextAlignment(.center)
                        .offset(y: -5)
                    Spacer()
                }
            }

            VStack {
                HostSectionView(
                    header: "RACE CODE",
                    title: model.raceCode?.uppercased() ?? "-",
                    imageName: "square.and.arrow.up",
                    disabled: model.raceCode == nil) {
                    self.presentModal(.activity)
                }
                .padding(.vertical, 16)

                HostSectionView(
                    header: "TYPE",
                    title: model.settings.isCustom ? "CUSTOM" : "STANDARD",
                    imageName: "gear",
                    disabled: false) {
                    self.presentModal(.settings)
                }
            }.frame(width: 220)

            Color.clear.frame(height: 50)
            Spacer()

            HStack {
                Color.clear.frame(width: 1)
                ForEach(model.connectedPlayers) { player in
                    WKRUIPlayerImageView(player: player, size: 44, effectSize: 3)
                        .padding(.all, 2)
                }
                .transition(.opacity)
                .scaleEffect(model.connectedPlayers.count < 6 ? 1 : 1.5 - 0.1 * CGFloat(model.connectedPlayers.count), anchor: .center)
                Color.clear.frame(width: 1)
            }
            .frame(maxHeight: 60)
            VStack {
                Text(model.status)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .transition(.opacity)
                    .id(model.status)
                ActivityIndicatorView().offset(x: 0, y: -5).opacity(model.matchStarting ? 0 : 1)
            }
            .padding(.bottom, 20)
        }
        .animation(.spring())
    }
}
