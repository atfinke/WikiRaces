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
    let bottomText: String
    let textOpacity: Double
    
    var body: some View {
        VStack {
            Divider().frame(height: 2)
            Spacer()
            Text(topText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.wkrSubtitleTextColor(for: colorScheme))
                .opacity(textOpacity)
                .animation(nil, value: topText)
                .animation(.easeInOut(duration: 0.4), value: textOpacity)
            Spacer().frame(height: 8)
            Text(bottomText)
                .font(Font(UIFont(monospaceSize: 16, weight: .medium)))
                .foregroundColor(.wkrTextColor(for: colorScheme))
                .opacity(textOpacity)
                .animation(nil, value: bottomText)
                .animation(.easeInOut(duration: 0.4), value: textOpacity)
            Spacer()
        }.frame(height: 75)
    }
    
}
