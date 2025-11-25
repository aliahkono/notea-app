//
//  SplashScreen.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var splashScreenController = SplashScreenController()
    @EnvironmentObject var databaseManager: DatabaseManager
    @State private var showAuthentication = false

    var body: some View {
        if splashScreenController.isActive {
            NavigationStack {
                HomeTabView()
            }
            .sheet(isPresented: $showAuthentication) {
                AuthenticationView()
            }
            .onAppear {
                // Show authentication after a delay if user is not signed in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if !databaseManager.isSignedIn {
                        showAuthentication = true
                    }
                }
            }
        } else {
            ZStack {
                Color.black.ignoresSafeArea()

                // Background glow
                if splashScreenController.currentFrame >= 1 {
                    Image("NoteaAppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width * 2,
                               height: UIScreen.main.bounds.height * 2)
                        .blur(radius: 100)
                        .opacity(splashScreenController.backgroundOpacity)
                        .scaleEffect(1.2)
                        .ignoresSafeArea()
                }

                // First Logo
                if splashScreenController.currentFrame == 0 || splashScreenController.currentFrame == 1 {
                    Image("NoteaAppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .cornerRadius(40)
                        .scaleEffect(splashScreenController.logoScale)
                        .opacity(splashScreenController.logoOpacity)
                }

                // Second Logo
                if splashScreenController.currentFrame >= 2 {
                    Image("NoteaAppLogo2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 160, height: 160)
                        .cornerRadius(40)
                        .scaleEffect(splashScreenController.secondLogoScale)
                        .opacity(splashScreenController.secondLogoOpacity)
                }
            }
            .onAppear {
                splashScreenController.startAnimationSequence()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(DatabaseManager.preview)
        .environmentObject(ThemeManager())
}
