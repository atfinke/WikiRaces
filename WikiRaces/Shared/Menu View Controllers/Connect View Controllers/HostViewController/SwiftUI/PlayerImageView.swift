//
//  PlayerImageView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/25/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import SwiftUI

struct PlayerImageView: View {
    
    let playerID: String
    let size: CGFloat
    let effectSize: CGFloat
    
    var body: some View {
        PlayerImageDatabase.shared.image(for: playerID)
            .renderingMode(.original)
            .resizable()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(radius: effectSize)
            .overlay(Circle().stroke(Color(UIColor.tertiarySystemBackground), lineWidth: effectSize))
    }
}
