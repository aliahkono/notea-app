import Foundation
import SwiftUI

class SplashScreenController: ObservableObject {
    @Published var currentFrame = 0
    @Published var isActive = false
    @Published var logoScale: CGFloat = 0.7
    @Published var logoOpacity: Double = 0
    @Published var backgroundOpacity: Double = 0
    @Published var secondLogoOpacity: Double = 0
    @Published var secondLogoScale: CGFloat = 0.8

    func startAnimationSequence() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeIn(duration: 1.0)) {
                self.logoOpacity = 1.0
                self.logoScale = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 1.0)) {
                    self.logoOpacity = 0.0
                    self.backgroundOpacity = 0.5
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.easeIn(duration: 1.0)) {
                        self.secondLogoOpacity = 1.0
                        self.secondLogoScale = 1.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.isActive = true
                    }
                }
            }
        }
    }
}