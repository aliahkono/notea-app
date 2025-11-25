//
//  HomeTabView.swift
//  Notea
//
//  Created by STUDENT on 8/27/25.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            // Background
            Color(hex: themeManager.selectedTheme.colors.background)
                .ignoresSafeArea()
                .frame(height: 60) // Adjusted height to make it smaller but not too small
                .clipShape(CustomTabBarShape())
                .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: -5)

            HStack(spacing: 30) { // Reduced spacing for better fit
                // Home Tab
                TabBarButton(icon: "house.fill", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }

                // Notes Tab
                TabBarButton(icon: "calendar", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }

                // Journal Tab
                TabBarButton(icon: "note.text", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }

                // Study Tab
                TabBarButton(icon: "hourglass", isSelected: selectedTab == 3) {
                    selectedTab = 3
                }

                // Profile Tab
                TabBarButton(icon: "pawprint.fill", isSelected: selectedTab == 4) {
                    selectedTab = 4
                }
            }
            .padding(.horizontal, 15) // Adjusted padding for better fit
        }
    }
}

struct TabBarButton: View {
    var icon: String
    var isSelected: Bool
    var action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(isSelected ? Color(hex: themeManager.selectedTheme.colors.primary) : Color.black.opacity(0.7))
                .frame(width: 50, height: 50)
        }
    }
}

struct CustomTabBarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - 30))
        path.addQuadCurve(to: CGPoint(x: 0, y: rect.height - 30), control: CGPoint(x: rect.width / 2, y: rect.height + 20))
        path.closeSubpath()
        return path
    }
}

struct HomeTabView: View {
    @State private var selectedTab = 0
    @State private var showSettings = false
    @State private var showTasks = false
    @State private var showPet = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                TabView(selection: $selectedTab) {
                    HomeView(showSettings: $showSettings, showTasks: $showTasks, showPet: $showPet)
                        .tag(0)

                    NotesTabView(showSettings: $showSettings)
                        .tag(1)

                    JournalTabView()
                        .tag(2)

                    StudyTabView()
                        .tag(3)

                    ProfileTabView()
                        .tag(4)
                }

                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                        .frame(width: geometry.size.width, height: 60) // Adjusted height
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsTabView()
        }
        .fullScreenCover(isPresented: $showTasks) {
            TaskTabView()
        }
        .fullScreenCover(isPresented: $showPet) {
            PetView()
        }
    }
}

struct HomeView: View {
    @Binding var showSettings: Bool
    @Binding var showTasks: Bool
    @Binding var showPet: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Color(hex: themeManager.selectedTheme.colors.background).ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.black)
                    }

                    Spacer()

                    Button {
                        showPet = true
                    } label: {
                        Circle()
                            .fill(Color.pink.opacity(0.3))
                            .frame(width: 70, height: 70)
                            .overlay(Text("🥚").font(.largeTitle))
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Hello there, User!")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Welcome, hope you’re having a productive day")
                        .font(.subheadline)
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding(.horizontal)
                .padding(.top, 10)

                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        Button {
                            showTasks = true
                        } label: {
                            HomeCard(
                                title: "Add your\nfirst task!",
                                subtitle: "Tap the paw below to start one",
                                bgColor: Color(red: 0.64, green: 0.63, blue: 0.53),
                                icon: "🐾"
                            )
                        }

                        Button {
                            showPet = true
                        } label: {
                            HomeCard(
                                title: "Pet Update",
                                subtitle: "Ready to hatch to meet you!",
                                bgColor: Color(red: 0.73, green: 0.55, blue: 0.78),
                                icon: "🐣"
                            )
                        }
                    }

                    HomeCard(
                        title: "This is your cozy space",
                        subtitle: "Add notes, track moods and your academic streak. Let your pet cheer you on!",
                        bgColor: Color(red: 1.0, green: 0.8, blue: 0.83),
                        icon: "🌸"
                    )
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()
            }
        }
    }
}

struct HomeCard: View {
    var title: String
    var subtitle: String
    var bgColor: Color
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.black)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.black.opacity(0.7))

            Spacer()

            HStack {
                Spacer()
                Text(icon)
                    .font(.title2)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 120)
        .background(bgColor)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.15), radius: 5, x: 4, y: 4)
    }
}

struct JournalView: View { var body: some View { Text("📓 Journal Tab") } }
struct StudyView: View { var body: some View { Text("⏳ Study Tab") } }
struct ProfileView: View { var body: some View { Text("🐾 Profile Tab") } }
struct TasksView: View { var body: some View { Text("✅ Tasks Tab") } }
struct PetView: View { var body: some View { Text("🥚 Pet Tab") } }
struct SettingsView: View { var body: some View { Text("⚙️ Settings Tab") } }

#Preview {
    HomeTabView()
        .environmentObject(ThemeManager())
        .environmentObject(DatabaseManager.preview)
}
