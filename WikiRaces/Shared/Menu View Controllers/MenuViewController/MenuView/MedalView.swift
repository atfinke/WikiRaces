//
//  MedalView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 3/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import SpriteKit

final class MedalView: SKView {

    // MARK: - Properties -

    private let medalScene = MedalScene(size: .zero)

    // MARK: - Initalization -

    init() {
        super.init(frame: .zero)
        presentScene(medalScene)

        ignoresSiblingOrder = true
        allowsTransparency = true
        isUserInteractionEnabled = false

        preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        medalScene.isPaused = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle -

    override func layoutSubviews() {
        super.layoutSubviews()
        scene?.size = bounds.size
    }

    func showMedals() {
        guard medalScene.isPaused else { return }
        let firstMedals = PlayerUserDefaultsStat.mpcRaceFinishFirst.value() +
            PlayerUserDefaultsStat.gkRaceFinishFirst.value()
        let secondMedals = PlayerUserDefaultsStat.mpcRaceFinishSecond.value() +
            PlayerUserDefaultsStat.gkRaceFinishSecond.value()
        let thirdMedals = PlayerUserDefaultsStat.mpcRaceFinishThird.value() +
            PlayerUserDefaultsStat.gkRaceFinishThird.value()
        let dnfCount = PlayerUserDefaultsStat.mpcRaceDNF.value() +
            PlayerUserDefaultsStat.gkRaceDNF.value()

        let metalCount = Int(firstMedals + secondMedals + thirdMedals)
        PlayerFirebaseAnalytics.log(event: .displayedMedals, attributes: ["Medals": metalCount])
        PlayerUserDefaultsStat.triggeredEasterEgg.increment()

        guard metalCount > 0 else { return }
        medalScene.showMedals(gold: Int(firstMedals),
                              silver: Int(secondMedals),
                              bronze: Int(thirdMedals),
                              dnf: Int(dnfCount))

        medalScene.isPaused = false
        UIImpactFeedbackGenerator().impactOccurred()
    }
}
