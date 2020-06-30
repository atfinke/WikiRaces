//
//  PlayerPlaceholderImageRenderer.swift
//  WikiRaces
//
//  Created by Andrew Finke on 6/30/20.
//  Copyright © 2020 Andrew Finke. All rights reserved.
//

import UIKit

struct PlayerPlaceholderImageRenderer {

    static private let colors: [UIColor] = [
        .systemRed,
        .systemGreen,
        .systemBlue,
        .systemOrange,
        .systemPink,
        .systemPurple,
        .systemTeal,
        .systemIndigo
    ]

    static func render(name: String) -> UIImage {
        let imageView = UIView(frame: CGRect(x: -100, y: -100, width: 100, height: 100))
        imageView.clipsToBounds = true

        let gradient = CAGradientLayer()
        gradient.frame = imageView.bounds
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)

        let shuffledColors = colors.shuffled()
        gradient.colors = [
            shuffledColors[0].cgColor,
            shuffledColors[1].cgColor
        ]
        imageView.layer.insertSublayer(gradient, at: 0)
        imageView.layer.cornerRadius = imageView.bounds.width / 2

        let label = UILabel(frame: imageView.bounds)
        label.text = name.first?.uppercased() ?? "-"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemRoundedFont(ofSize: 56, weight: .semibold)
        imageView.addSubview(label)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.preferredRange = .automatic

        guard let view = UIApplication.shared.windows.first else { return UIImage() }
        view.addSubview(imageView)
        let renderer = UIGraphicsImageRenderer(size: imageView.bounds.size, format: format)
        let image = renderer.image { ctx in
            imageView.layer.render(in: ctx.cgContext)
        }
        imageView.removeFromSuperview()
        return image
    }
}
