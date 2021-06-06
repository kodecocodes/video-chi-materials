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

import CoreHaptics

final class HapticManager {
  let sliceID: CHHapticAudioResourceID
  let nomNomID: CHHapticAudioResourceID
  let splashID: CHHapticAudioResourceID

  init() throws {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics
    else { throw CHHapticError(.notSupported) }

    let hapticEngine = try CHHapticEngine()
    self.hapticEngine = hapticEngine

    func id(name: String) throws -> CHHapticAudioResourceID {
      guard let url = Bundle.main.url(forResource: name, withExtension: "caf")
      else { throw CHHapticError(.resourceNotAvailable) }

      return try hapticEngine.registerAudioResource(url)
    }

    sliceID = try id(name: "Slice")
    nomNomID = try id(name: "NomNom")
    splashID = try id(name: "Splash")

    try hapticEngine.start()
    hapticEngine.isAutoShutdownEnabled = true

    let swish = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 0.5),
        .init(parameterID: .hapticSharpness, value: 1)
      ],
      relativeTime: 0,
      duration: 60
    )

    let pattern = try CHHapticPattern(events: [swish], parameters: [])
    swishPlayer = try hapticEngine.makeAdvancedPlayer(with: pattern)
  }

  private let hapticEngine: CHHapticEngine
  private var swishPlayer: CHHapticAdvancedPatternPlayer
}

// MARK: - internal
extension HapticManager {
  func startSwishPlayer() throws {
    try hapticEngine.start()
    try swishPlayer.start(atTime: CHHapticTimeImmediate)
  }

  func updateSwishPlayer(intensity: Float) throws {
    let intensity = CHHapticDynamicParameter(
      parameterID: .hapticIntensityControl,
      value: intensity,
      relativeTime: 0
    )

    try swishPlayer.sendParameters([intensity], atTime: CHHapticTimeImmediate)
  }

  func stopSwishPlayer() throws {
    try swishPlayer.stop(atTime: CHHapticTimeImmediate)
  }

  // MARK: Play Haptic Patterns

  func playSlice() throws {
    try playHaptic(pattern: slicePattern())
  }

  func playNomNom() throws {
    try playHaptic(pattern: nomNomPattern())
  }

  func playSplash() throws {
    try playHaptic(pattern: splashPattern())
  }
}

// MARK: - private
private extension HapticManager {
  func playHaptic(pattern: CHHapticPattern) throws {
    try hapticEngine.start()
    let player = try hapticEngine.makePlayer(with: pattern)
    try player.start(atTime: CHHapticTimeImmediate)
  }

  // MARK: Haptic Patterns

  func slicePattern() throws -> CHHapticPattern {
    let slice = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 0.6),
        .init(parameterID: .hapticSharpness, value: 0.8)
      ],
      relativeTime: 0,
      duration: 0.6
    )

    let snip = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 1),
        .init(parameterID: .hapticSharpness, value: 1)
      ],
      relativeTime: 0.08
    )

    let curve = CHHapticParameterCurve(
      parameterID: .hapticIntensityControl,
      controlPoints: [
        .init(relativeTime: 0, value: 0.2),
        .init(relativeTime: 0.08, value: 1),
        .init(relativeTime: 0.24, value: 0.2),
        .init(relativeTime: 0.34, value: 0.6),
        .init(relativeTime: 0.5, value: 0)
      ],
      relativeTime: 0
    )

    return try .init(
      events: [
        slice, snip,
        .init(audioResourceID: sliceID, parameters: [], relativeTime: 0)
      ],
      parameterCurves: [curve]
    )
  }

  func nomNomPattern() throws -> CHHapticPattern {
    let rumbles = [
      (intensity: 1, sharpness: 0.3, relativeTime: 0, duration: 0.15),
      (intensity: 0.4, sharpness: 0.1, relativeTime: 0.3, duration: 0.3)
    ].map {
      CHHapticEvent(
        eventType: .hapticContinuous,
        parameters: [
          .init(parameterID: .hapticIntensity, value: $0.intensity),
          .init(parameterID: .hapticSharpness, value: $0.sharpness)
        ],
        relativeTime: $0.relativeTime,
        duration: $0.duration
      )
    }

    let crunches = [
      (sharpness: 1, relativeTime: 0),
      (sharpness: 0.3, relativeTime: 0.3)
    ].map {
      CHHapticEvent(
        eventType: .hapticTransient,
        parameters: [
          .init(parameterID: .hapticIntensity, value: 1),
          .init(parameterID: .hapticSharpness, value: $0.sharpness)
        ],
        relativeTime: $0.relativeTime
      )
    }

    return try CHHapticPattern(
      events:
        rumbles + crunches
        + [.init(audioResourceID: nomNomID, parameters: [], relativeTime: 0)],
      parameters: []
    )
  }

  func splashPattern() throws -> CHHapticPattern {
    let splish = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 1),
        .init(parameterID: .hapticSharpness, value: 0.1)
      ],
      relativeTime: 0
    )

    let splash = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 0.5),
        .init(parameterID: .hapticSharpness, value: 0.1),
        .init(parameterID: .attackTime, value: 0.1),
        .init(parameterID: .decayTime, value: 0.3),
        .init(parameterID: .releaseTime, value: 0.2)
      ],
      relativeTime: 0.1,
      duration: 0.6
    )

    return try CHHapticPattern(
      events: [
        splish, splash,
        .init(audioResourceID: splashID, parameters: [], relativeTime: 0)
      ],
      parameters: []
    )
  }
}
