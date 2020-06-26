//
//  ResultsItemContentView.swift
//  WKRSwiftUI
//
//  Created by Andrew Finke on 6/24/20.
//

import SwiftUI

struct ResultsItemContentView: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    let item: ResultsContentViewModel.Item
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                PlayerImageView(playerID: item.id, size: 44, effectSize: 3)
                    .padding(.trailing, 6)
//                    .animation(nil)
//                    .id("Text")
                VStack(alignment: .leading) {
                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.wkrSubtitleTextColor(for: colorScheme))
                        .transition(.opacity)
                        .id("Text(item.subtitle)" + item.subtitle)
                    Text(item.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.wkrTextColor(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                        .id("Text(item.title)" + item.title)
                }
                
                Spacer()
                Color.clear.frame(width: 1, height: 1)
                if item.isReady {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.wkrTextColor(for: colorScheme))
                } else if item.isRacing {
                    ActivityIndicatorView()
                        .scaleEffect(0.8)
                } else {
                    Text(item.detail)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.wkrTextColor(for: colorScheme))
                }
            }
            .frame(minHeight: 50)
            
        }
    }
}
