//
//  SettingsTabView.swift
//  Notea
//
//  Created by STUDENT on 9/19/25.
//

import SwiftUI

// MARK: - Main Settings View

struct SettingsTabView: View {
    
    // An Environment variable to dismiss the view
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                
                // Top "Back" button and "Settings" title
                HStack(alignment: .center) {
                    Button(action: {
                        dismiss() // Dismisses the view and goes back
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    Text("Settings")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Invisible placeholder for symmetry
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(.clear)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // --- User Profile Section ---
                UserProfileSection()
                
                // --- Reminders & Notifications Section (single line) ---
                SectionView(title: "Reminders & Notifications", icon: "bell.fill", items: [
                    .init(name: "Study Timer Alerts", icon: "clock.fill"),
                    .init(name: "Journal Reminder", icon: "doc.text.fill"),
                    .init(name: "Pet Care Reminder", icon: "pawprint.fill")
                ], isMultiLine: false)
                
                // --- Account & Data and Extras Sections (side by side, multi-line) ---
                HStack(alignment: .top, spacing: 15) {
                    // Account & Data Section
                    SectionView(title: "Account & Data", icon: "person.circle.fill", items: [
                        .init(name: "Backup &\nSync", icon: "cloud.fill"),
                        .init(name: "Export\nNotes/\nJournals", icon: "doc.on.clipboard.fill"),
                        .init(name: "Privacy\nSettings", icon: "lock.fill")
                    ], isMultiLine: true)
                    .frame(maxWidth: .infinity)
                    
                    // Extras Section
                    SectionView(title: "Extras", icon: "ellipsis.circle.fill", items: [
                        .init(name: "About\nApp", icon: "info.circle.fill"),
                        .init(name: "Help &\nSupport", icon: "questionmark.circle.fill"),
                        .init(name: "Rate\nUs", icon: "star.fill")
                    ], isMultiLine: true)
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                
                // --- Bottom inspirational text ---
                VStack(spacing: 12) {
                    Image(systemName: "heart.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.pink)
                    
                    VStack(spacing: 4) {
                        Text("Keep shining")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        Text("You're doing great!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.7))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 20)
                
                Spacer(minLength: 20)
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.93),
                        Color(red: 0.95, green: 0.93, blue: 0.90)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            // Hide the default navigation bar so our custom button is the only one
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Helper Views

struct SectionView: View {
    let title: String
    let icon: String
    let items: [SectionItem]
    let isMultiLine: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.8))
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.top, 15)
            
            VStack(spacing: 10) {
                ForEach(items) { item in
                    NavigationLink(destination: getDestinationView(for: item.name)) {
                        HStack(spacing: 15) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18))
                                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                                .frame(width: 24, height: 24)
                            
                            if isMultiLine {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.black)
                                        .lineLimit(nil)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(item.name)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 12)
                }
            }
            .padding(.bottom, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.6))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, isMultiLine ? 0 : 20)
    }
    
    @ViewBuilder
    private func getDestinationView(for name: String) -> some View {
        VStack(spacing: 20) {
            Text("🚧")
                .font(.system(size: 60))
            
            Text("Coming Soon!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("The \(name.replacingOccurrences(of: "\n", with: " ")) feature is under development.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.96, blue: 0.93))
        .navigationTitle(name.replacingOccurrences(of: "\n", with: " "))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SectionItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
}

struct UserProfileSection: View {
    var body: some View {
        HStack(spacing: 20) {
            // Profile image with better styling
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.9, green: 0.7, blue: 0.9),
                                Color(red: 0.7, green: 0.5, blue: 0.8)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.white)
            }
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Username")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.black)
                
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 16))
                        .foregroundColor(.orange)
                    Text("Welcome back!")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.9),
                            Color(red: 0.98, green: 0.95, blue: 0.95)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Preview

struct SettingsTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SettingsTabView()
        }
    }
}
