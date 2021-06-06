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
  init() throws {
    guard CHHapticEngine.capabilitiesForHardware().supportsHaptics
    else { throw CHHapticError(.notSupported) }

    let hapticEngine = try CHHapticEngine()
    self.hapticEngine = hapticEngine

    try hapticEngine.start()
    hapticEngine.isAutoShutdownEnabled = true
  }

  private let hapticEngine: CHHapticEngine
}

// MARK: - internal
extension HapticManager {
  // MARK: Play Haptic Patterns

  func playSlice() throws {
    try hapticEngine.start()
    let player = try hapticEngine.makePlayer(with: slicePattern())
    try player.start(atTime: CHHapticTimeImmediate)
  }
}

// MARK: - private
private extension HapticManager {
  // MARK: Haptic Patterns

  func slicePattern() throws -> CHHapticPattern {
    let slice = CHHapticEvent(
      eventType: .hapticContinuous,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 0.35),
        .init(parameterID: .hapticSharpness, value: 0.25),
      ],
      relativeTime: 0,
      duration: 0.5
    )

    let snip = CHHapticEvent(
      eventType: .hapticTransient,
      parameters: [
        .init(parameterID: .hapticIntensity, value: 1),
        .init(parameterID: .hapticSharpness, value: 1)
      ],
      relativeTime: 0.08
    )

    return try .init(
      events: [slice, snip],
      parameters: []
    )
  }
}
