//
//  LoadingContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/27/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct LoadingContentView: View {

    @ObservedObject var model = LoadingContentViewModel()
    @Environment(\.colorScheme) var colorScheme: ColorScheme

    let cancel: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Text(self.model.title.uppercased())
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .padding()
                ActivityIndicatorView()
                    .opacity(self.model.activityOpacity)
                    .animation(.easeInOut(duration: 0.5), value: self.model.activityOpacity)
                Color.clear.frame(height: geometry.size.height * 0.6)
                Button(action: self.cancel, label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 22))
                        .padding()
                        .padding()
                })
                .foregroundColor(.wkrTextColor(for: self.colorScheme))
                Spacer()
            }
        }
    }
}
