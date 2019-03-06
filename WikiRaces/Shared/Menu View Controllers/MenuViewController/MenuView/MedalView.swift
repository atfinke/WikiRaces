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
        guard medalScene.isPaused else { return }
        let firstMedals = PlayerStat.mpcRaceFinishFirst.value() +
            PlayerStat.gkRaceFinishFirst.value()
        let secondMedals = PlayerStat.mpcRaceFinishSecond.value() +
            PlayerStat.gkRaceFinishSecond.value()
        let thirdMedals = PlayerStat.mpcRaceFinishThird.value() +
            PlayerStat.gkRaceFinishThird.value()

        var metalCount = Int(firstMedals + secondMedals + thirdMedals)
        PlayerMetrics.log(event: .displayedMedals, attributes: ["Medals": metalCount])
        PlayerStat.displayedMedals.increment()

        metalCount = 10
        guard metalCount > 0 else { return }
//
//        medalScene.showMedals(gold: Int(firstMedals),
//                              silver: Int(secondMedals),
//                              bronze: Int(thirdMedals))
        medalScene.showMedals(gold: Int(10),
                              silver: Int(10),
                              bronze: Int(10))
        medalScene.isPaused = false
    }
}
