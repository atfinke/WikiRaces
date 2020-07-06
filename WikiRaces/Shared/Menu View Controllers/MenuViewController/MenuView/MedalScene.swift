//
//  MedalScene.swift
//  WikiRaces
//
//  Created by Andrew Finke on 3/6/19.
//  Copyright © 2019 Andrew Finke. All rights reserved.
//

import SpriteKit

final class MedalScene: SKScene {

    // MARK: Properties -

    private let goldNode: SKNode
    private let silverNode: SKNode
    private let bronzeNode: SKNode
    private let dnfNode: SKNode

    // MARK: - Initalization -

    override init(size: CGSize) {
        let physicsBody = SKPhysicsBody(circleOfRadius: 5)
        physicsBody.allowsRotation = true
        physicsBody.linearDamping = 1.75
        physicsBody.angularDamping = 0.75

        func texture(for text: String, width: CGFloat = 50) -> SKTexture {
            let size = CGSize(width: width, height: width)
            let emojiRect = CGRect(origin: .zero, size: size)
            let emojiRenderer = UIGraphicsImageRenderer(size: size)
            return SKTexture(image: emojiRenderer.image { context in
                UIColor.clear.setFill()
                context.fill(emojiRect)
                let text = text
                let attributes = [
                    NSAttributedString.Key.font: UIFont.systemFont(ofSize: width - 5)
                ]
                text.draw(in: emojiRect, withAttributes: attributes)
            })
        }

        let goldNode = SKSpriteNode(texture: texture(for: "🥇"))
        goldNode.physicsBody = physicsBody
        self.goldNode = goldNode
        let silverNode = SKSpriteNode(texture: texture(for: "🥈"))
        silverNode.physicsBody = physicsBody
        self.silverNode = silverNode
        let bronzeNode = SKSpriteNode(texture: texture(for: "🥉"))
        bronzeNode.physicsBody = physicsBody
        self.bronzeNode = bronzeNode
        let dnfNode = SKSpriteNode(texture: texture(for: "❌", width: 20))
        dnfNode.physicsBody = physicsBody
        self.dnfNode = dnfNode

        super.init(size: size)
        anchorPoint = CGPoint(x: 0, y: 0)
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -7)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update -

    override func update(_ currentTime: TimeInterval) {
        for node in children where node.position.y < -50 {
            node.removeFromParent()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isPaused = self.children.isEmpty
        }
    }

    // MARK: - Other -

    func showMedals(gold: Int, silver: Int, bronze: Int, dnf: Int) {
        func createMedal(place: Int) {
            let node: SKNode
            if place == 1, let copy = goldNode.copy() as? SKNode {
                node = copy
            } else if place == 2, let copy = silverNode.copy() as? SKNode {
                node = copy
            } else if place == 3, let copy = bronzeNode.copy() as? SKNode {
                node = copy
            } else if place == 4, let copy = dnfNode.copy() as? SKNode {
                node = copy
            } else {
                return
            }

            let padding: CGFloat = 40
            let maxX = size.width - padding
            node.position = CGPoint(x: CGFloat.random(in: padding..<maxX),
                                    y: size.height + 50)
            node.zRotation = CGFloat.random(in: (-CGFloat.pi / 4)..<(CGFloat.pi / 4))
            addChild(node)

            var range: CGFloat = 0.5
            let impulse = CGVector(dx: CGFloat.random(in: 0..<range) - range / 2,
                                   dy: CGFloat.random(in: 0..<range) - range / 2)
            node.physicsBody?.applyImpulse(impulse)

            range = 0.001
            node.physicsBody?.applyTorque(CGFloat.random(in: 0..<range) - range / 2)
        }
        var places = [Int]()
        (0..<gold).forEach { _ in places.append(1) }
        (0..<silver).forEach {_ in  places.append(2)}
        (0..<bronze).forEach { _ in places.append(3)}
        (0..<dnf).forEach { _ in places.append(4)}

        for (index, place) in places.shuffled().enumerated() {
            scene?.run(.sequence([
                                    .wait(forDuration: Double(index) * 0.075),
                                    .run {
                                        createMedal(place: place)
                                    }]))
        }
    }
}
