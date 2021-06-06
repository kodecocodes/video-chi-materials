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
import AVFoundation

final class GameScene: SKScene {
  init?(_: Void = ()) throws {
    let size = CGSize(width: 375, height: 667)

    prize = {
      let prize = SKSpriteNode(imageNamed: .prize)
      prize.position = .init(x: size.width * 0.5, y: size.height * 0.7)
      prize.zPosition = Layer.prize
      let physicsBody = SKPhysicsBody(circleOfRadius: prize.size.height / 2)
      physicsBody.categoryBitMask = PhysicsCategory.prize
      physicsBody.collisionBitMask = 0
      physicsBody.density = 0.5
      prize.physicsBody = physicsBody
      return prize
    } ()

    crocodile = {
      let crocodile = SKSpriteNode(imageNamed: .crocMouthClosed)
      crocodile.position = .init(x: size.width * 0.75, y: size.height * 0.312)
      crocodile.zPosition = Layer.crocodile
      let physicsBody = SKPhysicsBody(
        texture: .init(imageNamed: .crocMask),
        size: crocodile.size
      )
      physicsBody.categoryBitMask = PhysicsCategory.crocodile
      physicsBody.collisionBitMask = 0
      physicsBody.contactTestBitMask = PhysicsCategory.prize
      physicsBody.isDynamic = false
      crocodile.physicsBody = physicsBody
      return crocodile
    } ()

    // MARK: Audio & Haptics

    guard let backgroundMusicPlayer = GameScene.backgroundMusicPlayer
    else { return nil }

    if !backgroundMusicPlayer.isPlaying {
      backgroundMusicPlayer.play()
    }

    do {
      let hapticManager = try HapticManager()
      self.hapticManager = hapticManager

      sliceSoundAction = .run {
        try? hapticManager.playSlice()
      }

      nomNomSoundAction = .run {
        try? hapticManager.playNomNom()
      }

      splashSoundAction = .run {
        try? hapticManager.playSplash()
      }
    } catch {
      hapticManager = nil

      sliceSoundAction = .playSoundFileNamed(SoundFile.slice, waitForCompletion: false)
      nomNomSoundAction = .playSoundFileNamed(SoundFile.nomNom, waitForCompletion: false)
      splashSoundAction = .playSoundFileNamed(SoundFile.splash, waitForCompletion: false)
    }

    super.init(size: size)
    scaleMode = .aspectFill

    physicsWorld.contactDelegate = self
    physicsWorld.gravity = .init(dx: 0, dy: -9.8)
    physicsWorld.speed = 1

    let background = SKSpriteNode(imageNamed: .background)
    background.anchorPoint = .zero
    background.position = .zero
    background.zPosition = Layer.background
    background.size = size

    let water = SKSpriteNode(imageNamed: .water)
    water.anchorPoint = .zero
    water.position = .zero
    water.zPosition = Layer.foreground
    water.size = .init(width: size.width, height: size.height * 0.2139)

    [prize, crocodile, background, water].forEach(addChild)

    guard let vineDataFile = Bundle.main.url(
      forResource: VineData.file,
      withExtension: nil
    )
    else { return nil }

    let vines = try PropertyListDecoder().decode(
      [VineData].self,
      from: Data(contentsOf: vineDataFile)
    )

    vines.enumerated().forEach {
      let anchorPoint = CGPoint(
        x: $0.element.relAnchorPoint.x * size.width,
        y: $0.element.relAnchorPoint.y * size.height
      )
      let vine = VineNode(length: $0.element.length, anchorPoint: anchorPoint, name: "\($0.offset)")
      vine.addToScene(self)
      vine.attach(toPrize: prize)
    }

    animateCrocodile()
  }

  private let crocodile: SKSpriteNode
  private let prize: SKSpriteNode
  private let sliceSoundAction: SKAction
  private let splashSoundAction: SKAction
  private let nomNomSoundAction: SKAction
  private let hapticManager: HapticManager?

  private var levelIsOver = false
  private var didCutVine = false
  private var particles: SKEmitterNode?

  @available(*, unavailable) required init!(coder _: NSCoder) { fatalError() }
}

// MARK: - private
private extension GameScene {
  static let backgroundMusicPlayer: AVAudioPlayer! = try?
    Bundle.main.url(
      forResource: SoundFile.backgroundMusic,
      withExtension: nil
    ).map {
      let player = try AVAudioPlayer(contentsOf: $0)
      player.numberOfLoops = -1
      return player
    }

  // MARK: Croc methods

  func animateCrocodile() {
    let wait = SKAction.wait(forDuration: .random(in: 2...4))
    crocodile.run(
      .repeatForever(.sequence([wait, .openMouth, wait, .closeMouth]))
    )
  }

  func runNomNomAnimation(delay: TimeInterval) {
    crocodile.removeAllActions()

    let wait = SKAction.wait(forDuration: delay)
    crocodile.run(
      .sequence([.closeMouth, wait, .openMouth, wait, .closeMouth])
    )
  }

  func showMoveParticles(touchPosition: CGPoint) {
    if
      particles == nil,
      let particles = SKEmitterNode(fileNamed: "Particle.sks")
    {
      particles.zPosition = 1
      particles.targetNode = self
      self.particles = particles
      addChild(particles)
    }

    particles?.position = touchPosition
  }

  // MARK: Game logic

  func checkIfVineCut(withBody body: SKPhysicsBody) {
    guard
      !didCutVine,
      let node = body.node,
      let name = node.name // if it has a name it must be a vine node
    else { return }

    // snip the vine
    node.removeFromParent()

    // fade out all nodes matching name
    enumerateChildNodes(withName: name) { node, _ in
      let fadeAway = SKAction.fadeOut(withDuration: 0.25)
      let removeNode = SKAction.removeFromParent()
      let sequence = SKAction.sequence([fadeAway, removeNode])
      node.run(sequence)
    }

    crocodile.removeAllActions()
    crocodile.texture = .init(imageNamed: .crocMouthOpen)
    animateCrocodile()
    run(sliceSoundAction)
    try? hapticManager?.playSlice()
    didCutVine = true
  }

  func switchToNewGame(transition: SKTransition) {
    let delay = SKAction.wait(forDuration: 1)
    let sceneChange = SKAction.run {
      try? GameScene().map {
        self.view?.presentScene(
          $0,
          transition: transition
        )
      }
    }

    run(.sequence([delay, sceneChange]))
  }
}

// MARK: - UIResponder
extension GameScene {
  override func touchesBegan(_: Set<UITouch>, with _: UIEvent?) {
    didCutVine = false
    try? hapticManager?.startSwishPlayer()
  }

  override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
    for touch in touches {
      let startPoint = touch.location(in: self)
      let endPoint = touch.previousLocation(in: self)

      // check if vine cut
      scene?.physicsWorld.enumerateBodies(
        alongRayStart: startPoint,
        end: endPoint
      ) { body, _, _, _ in
        self.checkIfVineCut(withBody: body)
      }

      // produce some nice particles
      showMoveParticles(touchPosition: startPoint)

      // update haptic player intensity
    }
  }

  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    particles?.removeFromParent()
    particles = nil
    try? hapticManager?.stopSwishPlayer()
  }
}

// MARK: - SKPhysicsContactDelegate
extension GameScene: SKPhysicsContactDelegate {
  override func update(_: TimeInterval) {
    guard !levelIsOver
    else { return }

    if prize.position.y <= 0 {
      levelIsOver = true
      switchToNewGame(transition: .fade(withDuration: 1))
    }
  }

  func didBegin(_ contact: SKPhysicsContact) {
    guard !levelIsOver
    else { return }

    if (contact.bodyA.node == crocodile && contact.bodyB.node == prize)
      || (contact.bodyA.node == prize && contact.bodyB.node == crocodile) {
      levelIsOver = true

      // shrink the pineapple away
      let sequence = SKAction.sequence(
        [.scale(to: 0, duration: 0.08), .removeFromParent()]
      )
      prize.run(sequence)
      run(nomNomSoundAction)
      runNomNomAnimation(delay: 0.15)
      
      // transition to next level
      switchToNewGame(transition: .doorway(withDuration: 1))
    }
  }
}

// MARK: - 
private extension SKAction {
  static let openMouth = setTexture(.init(imageNamed: .crocMouthOpen))
  static let closeMouth = setTexture(.init(imageNamed: .crocMouthClosed))
}

// MARK: -
private extension String {
  static let background = "Background"
  static let crocMask = "CrocMask"
  static let crocMouthClosed = "CrocMouthClosed"
  static let crocMouthOpen = "CrocMouthOpen"
  static let prize = "Pineapple"
  static let water = "Water"
}
