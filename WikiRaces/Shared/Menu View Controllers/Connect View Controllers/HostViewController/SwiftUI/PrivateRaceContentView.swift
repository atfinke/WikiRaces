//
//  PrivateRaceContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI
import WKRKit
import GameKit

struct PrivateRaceContentView: View {
    
    @ObservedObject var model: PrivateRaceContentViewModel
    @State private var isShareCodePresented: Bool = false
    @State private var isSettingsPresented: Bool = false
    
    let cancelAction: () -> Void
    let startMatch: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button(action: cancelAction, label: {
                    Image(systemName: "chevron.left")
                })
                    .opacity(model.matchStarting ? 0.2 : 1)
                Spacer()
                if model.matchStarting {
                    ActivityIndicatorView()
                } else {
                    Button(action: startMatch, label: {
                        Image(systemName: "play.fill")
                    })
                }
            }
            .foregroundColor(.black)
            .padding()
            .frame(height: 60)
            .allowsHitTesting(!model.matchStarting)
            
            Spacer()
            PlayerImageView(
                player: SwiftUIPlayer(id: GKLocalPlayer.local.alias),
                size: 100,
                effectSize: 5)
                .padding(.bottom, 20)
            
            VStack {
                PrivateRaceSectionView(
                    header: "CODE",
                    title: model.raceCode?.uppercased() ?? "-",
                    imageName: "square.and.arrow.up",
                    disabled: model.raceCode == nil) {
                        self.isShareCodePresented = true
                }
                .padding(.vertical, 16)
                .sheet(isPresented: $isShareCodePresented, content: {
                    ShareCodeView(raceCode: self.model.raceCode ?? "-")
                })
                
                PrivateRaceSectionView(
                    header: "TYPE",
                    title: model.settings.isCustom ? "CUSTOM" : "STANDARD",
                    imageName: "gear",
                    disabled: false) {
                        self.isSettingsPresented = true
                }
                .sheet(isPresented: $isSettingsPresented, content: {
                    RaceSettingsView(model: self.model)
                })
            }.frame(width: 220)
            
            Color.clear.frame(height: 50)
            Spacer()
            
            HStack {
                Color.clear.frame(width: 1)
                ForEach(model.connectedPlayers) { player in
                    PlayerImageView(player: player, size: 44, effectSize: 3)
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
        .overlay(Color.black.opacity(isShareCodePresented || isSettingsPresented ? 0.5 : 0).allowsHitTesting(false))
        .animation(.spring())
    }
}
