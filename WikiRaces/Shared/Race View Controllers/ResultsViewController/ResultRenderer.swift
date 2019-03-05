//
//  ResultRenderer.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/28/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

//swiftlint:disable function_body_length
class ResultRenderer {

    // MARK: - Types

    private class RenderView: UIView {
        var onLayout: (() -> Void)?
        override func layoutSubviews() {
            super.layoutSubviews()
            onLayout?()
        }
    }

    // MARK: - Properties

    let tintColor = #colorLiteral(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    private var isRendering = false

    // MARK: - Rendering

    func render(with results: WKRResultsInfo,
                for localPlayer: WKRPlayer,
                on canvasView: UIView,
                completion: @escaping (UIImage) -> Void) {

        guard !isRendering else { return }
        isRendering = true

        let view = RenderView()
        view.isHidden = true
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 25
        canvasView.addSubview(view)

        let innerView = UIView()
        innerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(innerView)

        let bannerView = createBannerView()
        let rankingHeaderView = createHeaderView(title: "rankings")
        let rankingView = createRankingView(for: results, localPlayer: localPlayer)

        let historyHeaderView: UIView
        if localPlayer.raceHistory?.entries == nil {
            historyHeaderView = UIView()
        } else {
            historyHeaderView = createHeaderView(title: localPlayer.name + "'s path")
        }
        let historyView = createHistoryView(for: localPlayer)

        innerView.addSubview(bannerView)
        innerView.addSubview(rankingHeaderView)
        innerView.addSubview(rankingView)
        innerView.addSubview(historyHeaderView)
        innerView.addSubview(historyView)

        let inset = CGFloat(20)
        let constraints = [
            view.widthAnchor.constraint(equalToConstant: 400),
            view.topAnchor.constraint(equalTo: canvasView.bottomAnchor),

            innerView.topAnchor.constraint(equalTo: view.topAnchor, constant: inset),
            innerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -inset),
            innerView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: inset),
            innerView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -inset),

            bannerView.topAnchor.constraint(equalTo: innerView.topAnchor),
            bannerView.widthAnchor.constraint(equalTo: innerView.widthAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: 90),

            rankingHeaderView.topAnchor.constraint(equalTo: bannerView.bottomAnchor),
            rankingHeaderView.widthAnchor.constraint(equalTo: innerView.widthAnchor),

            rankingView.topAnchor.constraint(equalTo: rankingHeaderView.bottomAnchor),
            rankingView.widthAnchor.constraint(equalTo: innerView.widthAnchor),

            historyHeaderView.topAnchor.constraint(equalTo: rankingView.bottomAnchor),
            historyHeaderView.widthAnchor.constraint(equalTo: innerView.widthAnchor),

            historyView.topAnchor.constraint(equalTo: historyHeaderView.bottomAnchor),
            historyView.bottomAnchor.constraint(equalTo: innerView.bottomAnchor),
            historyView.widthAnchor.constraint(equalTo: innerView.widthAnchor)
        ]

        view.onLayout = { [weak self] in
            self?.render(view: view, completion: completion)
        }
        NSLayoutConstraint.activate(constraints)
    }

    private func render(view: UIView, completion: (UIImage) -> Void) {
        let width = CGFloat(1020) / UIScreen.main.scale
        let ratio = view.bounds.width / width
        let size = CGSize(width: width, height: view.bounds.height / ratio)

        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        } else {
            format.prefersExtendedRange = false
        }

        let fullRenderer = UIGraphicsImageRenderer(size: view.bounds.size, format: format)
        view.isHidden = false
        let fullImage = fullRenderer.image { ctx in
            view.layer.render(in: ctx.cgContext)
        }
        view.removeFromSuperview()

        let resizedRenderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = resizedRenderer.image { _ in
             fullImage.draw(in: CGRect(origin: .zero, size: size))
        }

        #if DEBUG
        let pngData = resizedRenderer.pngData { _ in
            fullImage.draw(in: CGRect(origin: .zero, size: size))
        }
        let path = NSTemporaryDirectory().appending(Date().timeIntervalSince1970.description + ".png")
        let url = URL(fileURLWithPath: path)
        try? pngData.write(to: url)
        print(url)
        #endif

        isRendering = false
        completion(image)
    }

}
//swiftlint:enable function_body_length type_body_length cyclomatic_complexity
