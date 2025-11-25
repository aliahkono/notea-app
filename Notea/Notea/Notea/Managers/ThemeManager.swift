import Foundation
import SwiftUI

final class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme = .default

    init() {
        // Try to read saved UserProfile from UserDefaults to initialize theme
        if let data = UserDefaults.standard.data(forKey: "UserProfile") {
            if let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
                self.selectedTheme = decoded.selectedTheme
                return
            }
        }
        self.selectedTheme = .default
    }

    func apply(_ theme: AppTheme) {
        DispatchQueue.main.async {
            self.selectedTheme = theme
        }
    }
}
