//
//  ContentView.swift
//  WKRSwiftUI
//
//  Created by Andrew Finke on 6/24/20.
//

import SwiftUI
import UIKit
import WKRUIKit

private struct ReadyUpButton: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let isButtonEnabled: Bool
    let buttonFlashOpacity: Double
    let readyUpButtonPressed: () -> Void
    
    var body: some View {
        ZStack {
            if isButtonEnabled {
                Button(action: readyUpButtonPressed) {
                    Text("READY UP")
                        .font(.system(size: 16, weight: .semibold))
                        .kerning(4.4)
                        .frame(width: 160, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.wkrTextColor(for: colorScheme), lineWidth: 1.7)
                        )
                }
                .opacity(buttonFlashOpacity)
                .animation(.easeInOut(duration: 1), value: buttonFlashOpacity)
            }
        }
        .frame(height: 50)
        .animation(.easeInOut)
    }
}

private struct Table: View {
    let items: [ResultsContentViewModel.Item]
    let tappedPlayerID: (_ playerID: String) -> Void

    var body: some View {
        VStack {
            ForEach(items) { item  in
                ResultsItemContentView(item: item) {
                    tappedPlayerID(item.player.id)
                }
            }
        }
        .padding(.all, 20)
        .animation(.spring())
        .frame(maxWidth: 500)
    }
}

struct ResultsContentView: View {

    @ObservedObject var model: ResultsContentViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let readyUpButtonPressed: () -> Void
    let tappedPlayerID: (_ playerID: String) -> Void

    var body: some View {
        VStack {
            Spacer()
            Table(items: model.items, tappedPlayerID: tappedPlayerID)
            Spacer()
            ReadyUpButton(isButtonEnabled: model.isButtonEnabled, buttonFlashOpacity: model.buttonFlashOpacity, readyUpButtonPressed: readyUpButtonPressed)
            ListFooterView(
                topText: model.footerTopText,
                bottomStartText: model.footerBottomStartText,
                bottomNumberText: model.footerBottomNumberText,
                bottomEndText: model.footerBottomEndText,
                textOpacity: model.footerTextOpacity,
                dividerOpacity: model.footerDividerOpacity)
        }
        .foregroundColor(.wkrTextColor(for: colorScheme))
    }
}
