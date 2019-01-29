//
//  ResultRenderer.swift
//  WikiRaces
//
//  Created by Andrew Finke on 1/28/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import UIKit
import WKRKit

//swiftlint:disable function_body_length type_body_length
class ResultRenderer: NSObject {

    // MARK: - Properties

    private let tintColor = #colorLiteral(red: 54.0/255.0, green: 54.0/255.0, blue: 54.0/255.0, alpha: 1.0)
    private var isRendering = false

    // MARK: - Rendering

    func render(with results: WKRResultsInfo,
                for localPlayer: WKRPlayer,
                on canvasView: UIView,
                completion: @escaping (UIImage) -> Void) {
        
        guard !isRendering else { return }
        isRendering = true


        let view = UIView()
        view.isHidden = true
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 25
        view.layer.borderColor = tintColor.cgColor
        view.layer.borderWidth = 2
        canvasView.addSubview(view)

        let innerView = UIView()
        innerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(innerView)

        let bannerView = createBannerView()
        let rankingHeaderView = createHeaderView(title: "rankings")
        let rankingView = createRankingView(for: results, localPlayer: localPlayer)
        let historyHeaderView = createHeaderView(title: localPlayer.name + "'s path")
        let historyView = createHistoryView(for: results, localPlayer: localPlayer)

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
        NSLayoutConstraint.activate(constraints)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.render(view: view, completion: completion)
        }
    }

    private func render(view: UIView, completion: (UIImage) -> Void) {
        let width = CGFloat(960) / UIScreen.main.scale
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

//        Debugging
//        let pngData = resizedRenderer.pngData { _ in
//            fullImage.draw(in: CGRect(origin: .zero, size: size))
//        }
//        let url = URL(fileURLWithPath: NSTemporaryDirectory().appending(Date().timeIntervalSince1970.description + ".png"))
//        try? pngData.write(to: url)
//        print(url)

        isRendering = false
        completion(image)
    }

    // MARK: - Section Creation

    private func createHeaderView(title: String) -> UIView {
        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.text = title.uppercased()
        label.textAlignment = .left
        label.textColor = tintColor
        label.numberOfLines = 0
        headerView.addSubview(label)

        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false
        lineView.backgroundColor = tintColor
        lineView.layer.cornerRadius = 2
        headerView.addSubview(lineView)

        let constraints = [
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 25),
            label.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            label.rightAnchor.constraint(equalTo: headerView.rightAnchor),

            lineView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 5),
            lineView.leftAnchor.constraint(equalTo: headerView.leftAnchor),
            lineView.rightAnchor.constraint(equalTo: headerView.rightAnchor),
            lineView.heightAnchor.constraint(equalToConstant: 4),

            headerView.bottomAnchor.constraint(equalTo: lineView.bottomAnchor, constant: 0)
        ]
        NSLayoutConstraint.activate(constraints)

        return headerView
    }

    private func createBannerView() -> UIView {
        let bannerView = UIView()
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        let innerBannerView = UIView()
        innerBannerView.translatesAutoresizingMaskIntoConstraints = false
        bannerView.addSubview(innerBannerView)

        let imageView = UIImageView(image: UIImage(named: "PreviewIcon")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        innerBannerView.addSubview(imageView)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .semibold)
        titleLabel.text = "WikiRaces 3"
        titleLabel.textColor = tintColor
        innerBannerView.addSubview(titleLabel)

        let detailLabel = UILabel()
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        detailLabel.text = "RACE RESULTS"
        detailLabel.textColor = .darkGray
        innerBannerView.addSubview(detailLabel)

        let constraints = [
            innerBannerView.topAnchor.constraint(equalTo: bannerView.topAnchor, constant: 10),
            innerBannerView.bottomAnchor.constraint(equalTo: bannerView.bottomAnchor),
            innerBannerView.centerXAnchor.constraint(equalTo: bannerView.centerXAnchor, constant: -10),
            innerBannerView.widthAnchor.constraint(equalToConstant: 250),

            imageView.leftAnchor.constraint(equalTo: innerBannerView.leftAnchor),
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.heightAnchor.constraint(equalTo: innerBannerView.heightAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 10),
            titleLabel.rightAnchor.constraint(equalTo: innerBannerView.rightAnchor),

            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 0),
            detailLabel.leftAnchor.constraint(equalTo: titleLabel.leftAnchor)
        ]
        NSLayoutConstraint.activate(constraints)

        return bannerView
    }

    private func createRankingView(for results: WKRResultsInfo, localPlayer: WKRPlayer) -> UIView {
        let rankingView = UIView()
        rankingView.translatesAutoresizingMaskIntoConstraints = false

        let innerRankingsView = UIView()
        innerRankingsView.translatesAutoresizingMaskIntoConstraints = false
        rankingView.addSubview(innerRankingsView)

        let entrySpacing = CGFloat(15)
        var anchorView: UIView = innerRankingsView

        var constraints = [
            innerRankingsView.topAnchor.constraint(equalTo: rankingView.topAnchor),
            innerRankingsView.bottomAnchor.constraint(equalTo: rankingView.bottomAnchor),
            innerRankingsView.centerXAnchor.constraint(equalTo: rankingView.centerXAnchor),
            innerRankingsView.widthAnchor.constraint(equalTo: rankingView.widthAnchor)
        ]

        for index in 0..<results.playerCount {
            let player = results.raceRankingsPlayer(at: index)

            let nameLabel = UILabel()
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.numberOfLines = 0

            var placeString = (index + 1).description + "th"
            if index == 0 {
                placeString = "1st"
            } else if index == 1 {
                placeString = "2nd"
            } else if index == 2 {
                placeString = "3rd"
            }
            placeString += ": "
            let nameString = placeString + player.name

            let weight: UIFont.Weight = player == localPlayer ? .bold : .medium
            let nameFont = UIFont.systemFont(ofSize: 18, weight: weight)

            let style = NSMutableParagraphStyle()
            style.headIndent = 35

            let attributes: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .paragraphStyle: style
            ]
            let placeFont = UIFont(name: "Menlo-Bold", size: 14)!

            let mutableString = NSMutableAttributedString(string: nameString,
                                                          attributes: attributes)
            mutableString.addAttribute(.font,
                                       value: placeFont,
                                       range: NSRange(location: 0, length: placeString.count - 2))
            mutableString.addAttribute(.foregroundColor,
                                       value: UIColor.darkGray,
                                       range: NSRange(location: 0, length: placeString.count))
            nameLabel.attributedText = mutableString
            innerRankingsView.addSubview(nameLabel)

            let detailLabel = UILabel()
            detailLabel.translatesAutoresizingMaskIntoConstraints = false
            detailLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
            detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            detailLabel.textAlignment = .right

            var detailString = player.state.text
            if player.state == .foundPage,
                let history = player.raceHistory,
                let duration = DurationFormatter.string(for: history.duration, extended: true) {
                detailString = duration
            } else {
                detailString = player.state.extendedText
            }
            detailLabel.text = detailString
            innerRankingsView.addSubview(detailLabel)

            let anchor = index == 0 ? anchorView.topAnchor : anchorView.bottomAnchor
            constraints.append(contentsOf: [
                nameLabel.topAnchor.constraint(equalTo: anchor, constant: entrySpacing),
                nameLabel.leftAnchor.constraint(equalTo: innerRankingsView.leftAnchor),
                nameLabel.rightAnchor.constraint(equalTo: detailLabel.leftAnchor),

                detailLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
                detailLabel.bottomAnchor.constraint(equalTo: nameLabel.bottomAnchor),
                detailLabel.rightAnchor.constraint(equalTo: innerRankingsView.rightAnchor)
                ])
            anchorView = nameLabel
        }

        constraints.append(rankingView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor))
        NSLayoutConstraint.activate(constraints)

        return rankingView
    }

    private func createHistoryView(for results: WKRResultsInfo, localPlayer: WKRPlayer) -> UIView {
        let historyView = UIView()
        historyView.translatesAutoresizingMaskIntoConstraints = false

        var localPlayerHistory: [WKRHistoryEntry]?
        for index in 0..<results.playerCount {
            let player = results.raceRankingsPlayer(at: index)
            if player == localPlayer, let entries = player.raceHistory?.entries {
                localPlayerHistory = entries
            }
        }

        guard let entries = localPlayerHistory else { return historyView }
        var constraints = [NSLayoutConstraint]()
        let entrySpacing = CGFloat(15)
        var anchorView: UIView = historyView
        for (index, entry) in entries.enumerated() {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.numberOfLines = 0

            let num = index + 1
            let indexString = num.description + ". "
            let fullString = indexString + (entry.page.title ?? "")

            let shouldBold = index == entries.count - 1 && localPlayer.state == .foundPage
            let weight: UIFont.Weight = shouldBold ? .semibold : .medium
            let entryFont = UIFont.systemFont(ofSize: 18, weight: weight)
            let style = NSMutableParagraphStyle()
            style.headIndent = 18
            if num >= 10 {
                style.headIndent = 26
            }

            let attributes: [NSAttributedString.Key: Any] = [
                .font: entryFont,
                .paragraphStyle: style
            ]

            let indexFont = UIFont(name: "Menlo-Bold", size: 14)!

            let mutableString = NSMutableAttributedString(string: fullString,
                                                          attributes: attributes)
            mutableString.addAttribute(.font,
                                       value: indexFont,
                                       range: NSRange(location: 0, length: indexString.count - 2))
            mutableString.addAttribute(.foregroundColor,
                                       value: UIColor.darkGray,
                                       range: NSRange(location: 0, length: indexString.count))
            label.attributedText = mutableString

            historyView.addSubview(label)

            let anchor = index == 0 ? anchorView.topAnchor : anchorView.bottomAnchor
            constraints.append(contentsOf: [
                label.topAnchor.constraint(equalTo: anchor, constant: entrySpacing),
                label.leftAnchor.constraint(equalTo: historyView.leftAnchor),
                label.rightAnchor.constraint(equalTo: historyView.rightAnchor)
                ])
            anchorView = label
        }
        constraints.append(historyView.bottomAnchor.constraint(equalTo: anchorView.bottomAnchor))
        NSLayoutConstraint.activate(constraints)

        return historyView
    }

}
//swiftlint:enable function_body_length type_body_length
