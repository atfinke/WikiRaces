//
//  GameController.swift
//  WKRVisualizer Shared
//
//  Created by Andrew Finke on 2/19/18.
//  Copyright © 2018 Andrew Finke. All rights reserved.
//

import SceneKit

#if os(watchOS)
    import WatchKit
#endif

#if os(macOS)
    typealias SCNColor = NSColor
#else
    typealias SCNColor = UIColor
#endif

class GameController: NSObject, SCNSceneRendererDelegate {

    let scene: SCNScene
    let sceneRenderer: SCNSceneRenderer

    var index = 0
    var allResults = [[WKRPlayerResult]]()

    init(sceneRenderer renderer: SCNSceneRenderer) {
        sceneRenderer = renderer
        scene = SCNScene(named: "Art.scnassets/ship.scn")!

        super.init()

        sceneRenderer.delegate = self


        sceneRenderer.scene = scene

        let url = URL(fileURLWithPath: "/Users/andrewfinke/Desktop/WKRRaceState")
        allResults = WKRResultsGetter.fetchResults(atDirectory: url)


        gen(index: 0)



    }

    func next() {
        index = min(100, index + 1)
        gen(index: index)
    }

    func prev() {
        index = max(0, index - 1)
        gen(index: index)
    }
    

    func gen(index: Int) {

        for node in scene.rootNode.childNodes {
            if node.name?.count ?? 0 < 5 {
                node.removeFromParentNode()
            }
        }


        func generateRandomColor() -> SCNColor {
            let hue : CGFloat = CGFloat(arc4random() % 256) / 256 // use 256 to get full range from 0.0 to 1.0
            let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from white
            let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5 // from 0.5 to 1.0 to stay away from black

            return SCNColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
        }

        var colors: [SCNColor] = [.red, .green, .blue, .cyan, .yellow, .magenta, .orange, .purple, .brown]


        let results = allResults[index]


        let maxTime = results.map({ $0.pages }).reduce([], +).sorted(by: { (lhs, rhs) -> Bool in
            return lhs.duration > rhs.duration
        })[0].duration


        var colorIndex = 0


        var existingPages = [String: [SCNNode]]()
        var existingColors = [String: SCNColor]()

        for (playerIndex, player) in results.enumerated() {

            var lastOffset: SCNFloat = 0.0

            for (_, page) in player.pages.enumerated() {


                let someVal = SCNFloat(page.duration) / SCNFloat(maxTime)
                let radius = 1.0 + 5 * someVal
                let geo = SCNSphere(radius: radius)

                geo.firstMaterial?.diffuse.contents  = SCNColor.lightGray


                let node = SCNNode(geometry: geo)

                let offset = lastOffset + radius
                node.position = SCNVector3(offset,CGFloat(playerIndex) * 12.0,0)
                lastOffset = offset + radius + 1


                scene.rootNode.addChildNode(node)

                if let existingNodes = existingPages[page.title] {

                    let color: SCNColor
                    if let existingColor = existingColors[page.title] {
                        color = existingColor
                    } else {
                        colorIndex += 1
                        if colorIndex > colors.count - 1 {
                            colors.append(generateRandomColor())
                        }
                        color = colors[colorIndex]
                        existingColors[page.title] = color
                    }

                    for existingNode in existingNodes {

                        let newNode = SCNNode()
                        newNode.position = node.position
                        scene.rootNode.addChildNode(newNode)


                        geo.firstMaterial?.diffuse.contents = color
                        existingNode.geometry?.firstMaterial?.diffuse.contents = color

                        if existingNode.position.y == node.position.y {

                            let dif = node.position.x - existingNode.position.x

                            let midPoint = SCNVector3((existingNode.position.x + node.position.x) / 2,CGFloat(playerIndex) * 12.0, dif)

                            let midNode = SCNNode()
                            midNode.position = midPoint
                            scene.rootNode.addChildNode(midNode)

                            scene.rootNode.addChildNode(newNode.buildLineInTwoPointsWithRotation(
                                from: midPoint, to: newNode.position, radius: 0.1, color: color))

                            scene.rootNode.addChildNode(midNode.buildLineInTwoPointsWithRotation(
                                from: existingNode.position, to: midNode.position, radius: 0.1, color: color))

                        } else {
                            scene.rootNode.addChildNode(newNode.buildLineInTwoPointsWithRotation(
                                from: node.position, to: existingNode.position, radius: 0.1, color: color))
                        }


                    }

                    existingPages[page.title] = existingNodes + [node]
                } else {
                    existingPages[page.title] = [node]
                }

            }
        }

    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // Called before each frame is rendered
    }

}


func normalizeVector(_ iv: SCNVector3) -> SCNVector3 {
    let length = sqrt(iv.x * iv.x + iv.y * iv.y + iv.z * iv.z)
    if length == 0 {
        return SCNVector3(0.0, 0.0, 0.0)
    }

    return SCNVector3( iv.x / length, iv.y / length, iv.z / length)

}

extension SCNNode {

    func buildLineInTwoPointsWithRotation(from startPoint: SCNVector3,
                                          to endPoint: SCNVector3,
                                          radius: CGFloat,
                                          color: SCNColor) -> SCNNode {
        let w = SCNVector3(x: endPoint.x-startPoint.x,
                           y: endPoint.y-startPoint.y,
                           z: endPoint.z-startPoint.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))

        if l == 0.0 {
            // two points together.
            let sphere = SCNSphere(radius: radius)
            sphere.firstMaterial?.diffuse.contents = color
            self.geometry = sphere
            self.position = startPoint
            return self

        }

        let cyl = SCNCylinder(radius: radius, height: l)
        cyl.firstMaterial?.diffuse.contents = color

        self.geometry = cyl

        //original vector of cylinder above 0,0,0
        let ov = SCNVector3(0, l/2.0,0)
        //target vector, in new coordination
        let nv = SCNVector3((endPoint.x - startPoint.x)/2.0, (endPoint.y - startPoint.y)/2.0,
                            (endPoint.z-startPoint.z)/2.0)

        // axis between two vector
        let av = SCNVector3( (ov.x + nv.x)/2.0, (ov.y+nv.y)/2.0, (ov.z+nv.z)/2.0)

        //normalized axis vector
        let av_normalized = normalizeVector(av)
        let q0 = SCNFloat(0.0) //cos(angel/2), angle is always 180 or M_PI
        let q1 = SCNFloat(av_normalized.x) // x' * sin(angle/2)
        let q2 = SCNFloat(av_normalized.y) // y' * sin(angle/2)
        let q3 = SCNFloat(av_normalized.z) // z' * sin(angle/2)

        let r_m11 = q0 * q0 + q1 * q1 - q2 * q2 - q3 * q3
        let r_m12 = 2 * q1 * q2 + 2 * q0 * q3
        let r_m13 = 2 * q1 * q3 - 2 * q0 * q2
        let r_m21 = 2 * q1 * q2 - 2 * q0 * q3
        let r_m22 = q0 * q0 - q1 * q1 + q2 * q2 - q3 * q3
        let r_m23 = 2 * q2 * q3 + 2 * q0 * q1
        let r_m31 = 2 * q1 * q3 + 2 * q0 * q2
        let r_m32 = 2 * q2 * q3 - 2 * q0 * q1
        let r_m33 = q0 * q0 - q1 * q1 - q2 * q2 + q3 * q3

        self.transform.m11 = r_m11
        self.transform.m12 = r_m12
        self.transform.m13 = r_m13
        self.transform.m14 = 0.0

        self.transform.m21 = r_m21
        self.transform.m22 = r_m22
        self.transform.m23 = r_m23
        self.transform.m24 = 0.0

        self.transform.m31 = r_m31
        self.transform.m32 = r_m32
        self.transform.m33 = r_m33
        self.transform.m34 = 0.0

        self.transform.m41 = (startPoint.x + endPoint.x) / 2.0
        self.transform.m42 = (startPoint.y + endPoint.y) / 2.0
        self.transform.m43 = (startPoint.z + endPoint.z) / 2.0
        self.transform.m44 = 1.0
        return self
    }
}
