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
                .padding(.bottom, 10)
            Text(topText)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.wkrSubtitleTextColor(for: colorScheme))
                .opacity(textOpacity)
                .animation(nil, value: topText)
                .animation(.easeInOut(duration: 0.4), value: textOpacity)
            Spacer()
            Text(bottomText)
                .font(Font(UIFont(monospaceSize: 16, weight: .medium)))
                .foregroundColor(.wkrTextColor(for: colorScheme))
                .opacity(textOpacity)
                .animation(nil, value: bottomText)
                .animation(.easeInOut(duration: 0.4), value: textOpacity)
            
        }
        .frame(minHeight: 55, maxHeight: 55)
        .padding(.bottom, 20)
    }
    
}
