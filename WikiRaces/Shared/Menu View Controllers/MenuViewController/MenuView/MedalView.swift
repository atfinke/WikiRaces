//
//  MedalView.swift
//  WikiRaces
//
//  Created by Andrew Finke on 3/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import SpriteKit

class MedalView: SKView {

    // MARK: - Properties

    let medalScene = MedalScene(size: .zero)

    // MARK: - Initalization

    init() {
        super.init(frame: .zero)
        presentScene(medalScene)

        ignoresSiblingOrder = true
        allowsTransparency = true
        isUserInteractionEnabled = false
        medalScene.isPaused = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Life Cycle

    override func layoutSubviews() {
        super.layoutSubviews()
        scene?.size = bounds.size
    }

    func showMedals() {
        guard !medalScene.isActive else { return }
        let firstMedals = PlayerDatabaseStat.mpcRaceFinishFirst.value() +
            PlayerDatabaseStat.gkRaceFinishFirst.value()
        let secondMedals = PlayerDatabaseStat.mpcRaceFinishSecond.value() +
            PlayerDatabaseStat.gkRaceFinishSecond.value()
        let thirdMedals = PlayerDatabaseStat.mpcRaceFinishThird.value() +
            PlayerDatabaseStat.gkRaceFinishThird.value()
        let dnfCount = PlayerDatabaseStat.mpcRaceDNF.value() +
            PlayerDatabaseStat.gkRaceDNF.value()

        let metalCount = Int(firstMedals + secondMedals + thirdMedals)
        PlayerAnonymousMetrics.log(event: .displayedMedals, attributes: ["Medals": metalCount])
        PlayerDatabaseStat.triggeredEasterEgg.increment()

        guard metalCount > 0 else { return }
        medalScene.showMedals(gold: Int(firstMedals),
                              silver: Int(secondMedals),
                              bronze: Int(thirdMedals),
                              dnf: Int(dnfCount))

        medalScene.isActive = true
        UIImpactFeedbackGenerator().impactOccurred()
    }
}
