//
//  ContentView.swift
//  WKRSwiftUI
//
//  Created by Andrew Finke on 6/24/20.
//

import SwiftUI
import UIKit
import WKRUIKit

struct ResultsContentView: View {
    
    @ObservedObject var model: ResultsContentViewModel
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let readyUpButtonPressed: () -> Void
    let tapped: (_ playerID: String) -> Void

    var body: some View {
        VStack {
            Spacer()
            VStack() {
                ForEach(model.items) { item  in
                    ResultsItemContentView(item: item) {
                        self.tapped(item.player.id)
                    }
                }
            }
            .padding(.all, 20)
            .animation(.spring())
            .frame(maxWidth: 500)
            Spacer()
            
            ZStack {
                if model.buttonEnabled {
                    Button(action: readyUpButtonPressed) {
                        Text("READY UP")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .kerning(4.4)
                            .foregroundColor(Color.wkrTextColor(for: colorScheme))
                            .frame(width: 160, height: 36)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.wkrTextColor(for: colorScheme), lineWidth: 1.7)
                            )
                    }
                    .opacity(model.buttonFlashOpacity)
                    .animation(.easeInOut(duration: 1), value: model.buttonFlashOpacity)
                }
            }
            .frame(height: 50)
            .animation(.easeInOut)
            ListFooterView(topText: model.footerTopText, bottomText: model.footerBottomText, textOpacity: model.footerOpacity)
        }
    }
}
