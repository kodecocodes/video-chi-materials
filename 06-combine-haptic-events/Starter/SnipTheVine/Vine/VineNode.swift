/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SpriteKit

final class VineNode: SKNode {
  private let length: Int
  private let anchorPoint: CGPoint
  private var vineSegments: [SKNode] = []

  init(length: Int, anchorPoint: CGPoint, name: String) {
    self.length = length
    self.anchorPoint = anchorPoint

    super.init()

    self.name = name
  }

  required init?(coder aDecoder: NSCoder) {
    length = aDecoder.decodeInteger(forKey: "length")
    anchorPoint = aDecoder.decodeCGPoint(forKey: "anchorPoint")

    super.init(coder: aDecoder)
  }

  func addToScene(_ scene: SKScene) {
    // add vine to scene
    zPosition = Layer.vine
    scene.addChild(self)

    // create vine holder
    let vineHolder = SKSpriteNode(imageNamed: .vineHolder)
    vineHolder.position = anchorPoint
    vineHolder.zPosition = 1

    addChild(vineHolder)

    vineHolder.physicsBody = SKPhysicsBody(circleOfRadius: vineHolder.size.width / 2)
    vineHolder.physicsBody?.isDynamic = false
    vineHolder.physicsBody?.categoryBitMask = PhysicsCategory.vineHolder
    vineHolder.physicsBody?.collisionBitMask = 0

    // add each of the vine parts
    for i in 0..<length {
      let vineSegment = SKSpriteNode(imageNamed: .vineTexture)
      let offset = vineSegment.size.height * CGFloat(i + 1)
      vineSegment.position = CGPoint(x: anchorPoint.x, y: anchorPoint.y - offset)
      vineSegment.name = name

      vineSegments.append(vineSegment)
      addChild(vineSegment)

      vineSegment.physicsBody = SKPhysicsBody(rectangleOf: vineSegment.size)
      vineSegment.physicsBody?.categoryBitMask = PhysicsCategory.vine
      vineSegment.physicsBody?.collisionBitMask = PhysicsCategory.vineHolder
    }

    // set up joint for vine holder
    // swiftlint:disable force_unwrapping
    let joint = SKPhysicsJointPin.joint(
      withBodyA: vineHolder.physicsBody!,
      bodyB: vineSegments[0].physicsBody!,
      anchor: .init(
        x: vineHolder.frame.midX,
        y: vineHolder.frame.midY
      )
    )

    scene.physicsWorld.add(joint)

    // set up joints between vine parts
    for i in 1..<length {
      let nodeA = vineSegments[i - 1]
      let nodeB = vineSegments[i]
      let joint = SKPhysicsJointPin.joint(
        withBodyA: nodeA.physicsBody!,
        bodyB: nodeB.physicsBody!,
        anchor: .init(
          x: nodeA.frame.midX,
          y: nodeA.frame.minY
        )
      )

      scene.physicsWorld.add(joint)
      // swiftlint:enable force_unwrapping
    }
  }

  func attach(toPrize prize: SKSpriteNode) {
    // align last segment of vine with prize
    // swiftlint:disable force_unwrapping
    let lastNode = vineSegments.last!
    lastNode.position = .init(
      x: prize.position.x,
      y: prize.position.y + prize.size.height * 0.1
    )

    // set up connecting joint
    let joint = SKPhysicsJointPin.joint(
      withBodyA: lastNode.physicsBody!,
      bodyB: prize.physicsBody!,
      anchor: lastNode.position
    )

    prize.scene?.physicsWorld.add(joint)
    // swiftlint:enable force_unwrapping
  }
}

private extension String {
  static let vineTexture = "VineTexture"
  static let vineHolder = "VineHolder"
}
