//
//  PreRaceContentView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 5/4/21.
//  Copyright © 2021 Andrew Finke. All rights reserved.
//

import SwiftUI

private struct Header: View {
    let title: String
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 20, weight: .medium, design: .rounded))
            .padding()
    }
}

private struct ProgressView: View {
    
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    let progress: CGFloat
    let state: PreRaceContentViewModel.ProgressDisplayState
    
    private let lineWidth: CGFloat = 3
    private let size: CGFloat = 32
    var body: some View {
        ZStack {
            ZStack {
                ZStack {
                    Circle()
                        .stroke(Color.wkrSubtitleTextColor(for: colorScheme)
                                    .opacity(0.2), lineWidth: lineWidth)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.wkrTextColor(for: colorScheme),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                }
                .opacity(progress >= 1 ? 0 : 1)
                .scaleEffect(progress >= 1 ? 0 : 1)
                .animation(.spring(), value: progress)
                
                Image(systemName: "checkmark.circle.fill")
                    .resizable()
                    .opacity(progress >= 1 ? 1 : 0)
                    .scaleEffect(progress >= 1 ? 1 : 0)
                    .animation(.spring(), value: progress)
            }
            .opacity(state == .progress ? 1 : 0)
            
            ActivityIndicatorView()
                .opacity(state == .spinner ? 1 : 0)
        }
        .animation(.easeInOut(duration: 0.5), value: state)
        .frame(width: size, height: size)
    }
}

private struct Footer: View {
    
    let disclaimerButtonTitle: String
    let disclaimerButtonOpacity: Double
    let disclaimerButton: (() -> Void)?
    let cancel: () -> Void
    var body: some View {
        Button(action: {
            disclaimerButton?()
        }, label: {
            Text(disclaimerButtonTitle)
                .font(.system(size: 16, weight: .regular, design: .rounded))
//                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(.systemBlue))
                .opacity(disclaimerButtonOpacity)
                .animation(.easeInOut(duration: 0.5), value: disclaimerButtonOpacity)
        })
        Button(action: self.cancel, label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 22))
                .padding()
                .padding()
        })
        Spacer()
    }
}

struct PreRaceContentView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @ObservedObject var model = PreRaceContentViewModel()
    
    let cancel: () -> Void
    let disclaimerButton: (() -> Void)?
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                Header(title: model.title)
                ProgressView(progress: model.progress,
                             state: model.progressDisplayState)
                Color.clear.frame(height: geometry.size.height * 0.5)
                
                Footer(disclaimerButtonTitle: model.disclaimerButtonTitle,
                       disclaimerButtonOpacity: model.disclaimerButtonOpacity,
                       disclaimerButton: disclaimerButton,
                       cancel: cancel)
            }
            .foregroundColor(.wkrTextColor(for: colorScheme))
        }
    }
}
