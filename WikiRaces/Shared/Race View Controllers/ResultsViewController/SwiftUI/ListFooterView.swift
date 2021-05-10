//
//  ListFooterView.swift
//  WKRSwiftUI
//
//  Created by Andrew Finke on 6/24/20.
//

import SwiftUI
import WKRUIKit

struct ListFooterView: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let topText: String
    let bottomStartText: String
    let bottomNumberText: String
    let bottomEndText: String
    
    let textOpacity: Double
    let dividerOpacity: Double
    
    var body: some View {
        VStack {
            Divider()
                .frame(height: 2)
                .opacity(dividerOpacity)
                .animation(.easeInOut(duration: 0.4), value: dividerOpacity)
            Spacer()
            Text(topText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.wkrSubtitleTextColor(for: colorScheme))
                .opacity(textOpacity)
                .animation(nil, value: topText)
                .animation(.easeInOut(duration: 0.4), value: textOpacity)
            Spacer().frame(height: 8)
            HStack(spacing: 0) {
                Text(bottomStartText)
                if !bottomNumberText.isEmpty {
                    Text(bottomNumberText)
                        .font(Font(UIFont(monospaceSize: 16, weight: .medium)))
                    Text(bottomEndText)
                }
            }
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.wkrTextColor(for: colorScheme))
            .opacity(textOpacity)
            .animation(nil, value: bottomStartText)
            .animation(.easeInOut(duration: 0.4), value: textOpacity)
            
            Spacer()
        }.frame(height: 75)
    }
    
}
