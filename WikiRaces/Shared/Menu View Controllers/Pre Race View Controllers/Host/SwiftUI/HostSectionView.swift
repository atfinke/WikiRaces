//
//  HostSectionView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct HostSectionView: View {

    // MARK: - Properties -

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let header: String
    let title: String

    let imageName: String

    let disabled: Bool
    let action: () -> Void

    // MARK: - Body -

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(header)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.wkrSubtitleTextColor(for: colorScheme))
                    .multilineTextAlignment(.leading)
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.leading)
                    .transition(.opacity)
                    .id(title)
            }
            Spacer()
            Button(action: action, label: {
                Image(systemName: imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24)
                    .font(.system(size: 30, weight: .regular, design: .rounded))
            })
            .opacity(disabled ? 0.2 : 1)
            .disabled(disabled)
            .animation(.spring())
        }
        .foregroundColor(.wkrTextColor(for: colorScheme))
    }
}
