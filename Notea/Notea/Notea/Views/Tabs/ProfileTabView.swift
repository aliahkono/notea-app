//
//  ProfileTabView.swift
//  Notea
//
//  Created by STUDENT on 9/19/25.
//

import SwiftUI
import PhotosUI

struct ProfileTabView: View {
    @StateObject private var profileController = ProfileController()
    @State private var showSettings = false
    @State private var showAvatarCustomization = false
    @State private var showThemePicker = false
    @State private var isEditingUsername = false
    @State private var showStats = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: - Header Following OOP Principles
                ProfileHeaderView(
                    profile: profileController.userProfile,
                    isEditingUsername: $isEditingUsername,
                    onUsernameUpdate: { newUsername in
                        profileController.updateUsername(newUsername)
                    }
                )
                .padding(.top, 30)

                // MARK: - Profile & Customization Section
                ProfileCustomizationSection(
                    showAvatarCustomization: $showAvatarCustomization,
                    showThemePicker: $showThemePicker,
                    isEditingUsername: $isEditingUsername
                )

                // MARK: - Achievements & Progress Section Following OOP
                ProfileStatsSection(profileController: profileController)

                // MARK: - Footer Buttons
                HStack(spacing: 20) {
                    Button(action: {
                        showStats = true
                    }) {
                        FooterButton(icon: "chart.bar.fill", label: "View Stats", color: Color(red: 0.76, green: 0.92, blue: 0.60))
                    }
                    FooterButton(icon: "pawprint.fill", label: "Pet Care", color: Color(red: 0.92, green: 0.76, blue: 0.60))
                }
                .padding(.top, 10)

                Spacer()
            }
            .padding()
            .background(Color(red: 0.98, green: 0.96, blue: 0.94))
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.black)
                    }
                }
            }
            .navigationDestination(isPresented: $showSettings) {
                SettingsTabView()
            }
            .navigationDestination(isPresented: $showStats) {
                StatsViewTab()
            }
            .sheet(isPresented: $showAvatarCustomization) {
                AvatarCustomizationView(
                    avatarImage: Binding(
                        get: { profileController.userProfile.avatarImage },
                        set: { profileController.updateAvatarImage($0) }
                    )
                )
            }
            .sheet(isPresented: $showThemePicker) {
                ThemePickerView(
                    selectedTheme: Binding(
                        get: { profileController.userProfile.selectedTheme },
                        set: { profileController.updateTheme($0) }
                    )
                )
            }
        }
    }
}

// MARK: - Supporting View Components Following OOP Principles
// MARK: - ProfileHeaderView Refactor
struct ProfileHeaderView: View {
    let profile: UserProfile
    @Binding var isEditingUsername: Bool
    let onUsernameUpdate: (String) -> Void
    @State private var tempUsername: String = ""

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                HeartShape()
                    .fill(Color(red: 0.98, green: 0.88, blue: 0.90))
                    .frame(width: 120, height: 120)
                    .overlay(
                        HeartShape()
                            .stroke(Color(red: 0.96, green: 0.60, blue: 0.76), lineWidth: 4)
                    )

                if let avatarImage = profile.avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .clipShape(HeartShape())
                        .overlay(
                            HeartShape()
                                .stroke(Color.white, lineWidth: 2)
                        )
                }
            }

            if isEditingUsername {
                TextField("Enter new username", text: $tempUsername)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .onAppear {
                        tempUsername = profile.username
                    }

                Button(action: {
                    onUsernameUpdate(tempUsername)
                    isEditingUsername = false
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            } else {
                Text(profile.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }

            Text("User Profile")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct ProfileCustomizationSection: View {
    @Binding var showAvatarCustomization: Bool
    @Binding var showThemePicker: Bool
    @Binding var isEditingUsername: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profile & Customization")
                .font(.headline)
                .foregroundColor(.black)
                .padding([.top, .leading])

            HStack(spacing: 20) {
                Button(action: {
                    showAvatarCustomization = true
                }) {
                    ProfileButton(icon: "face.smiling.fill", label: "Avatar", color: Color(red: 0.70, green: 0.60, blue: 0.96))
                }

                Button(action: {
                    isEditingUsername = true
                }) {
                    ProfileButton(icon: "pencil.circle.fill", label: "Username", color: Color(red: 0.96, green: 0.60, blue: 0.76))
                }

                Button(action: {
                    showThemePicker = true
                }) {
                    ProfileButton(icon: "paintpalette.fill", label: "Theme", color: Color(red: 0.60, green: 0.88, blue: 0.96))
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 0.98, green: 0.90, blue: 0.92), Color(red: 0.96, green: 0.88, blue: 0.90)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
}

struct ProfileStatsSection: View {
    @ObservedObject var profileController: ProfileController
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Achievements & Progress")
                .font(.headline)
                .padding(.leading, 15)

            if profileController.getAchievements().isEmpty && profileController.getTotalStudySessions() == 0 {
                Text("No progress yet! Start studying to unlock achievements.")
                    .foregroundColor(.gray)
                    .font(.subheadline)
                    .padding(.leading, 15)
            } else {
                VStack(spacing: 12) {
                    HStack {
                        VStack {
                            Text("\(profileController.getTotalStudySessions())")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Sessions")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(Int(profileController.getTotalStudyTime() / 3600))h")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Study Time")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("\(profileController.getAchievements().count)")
                                .font(.title2)
                                .fontWeight(.bold)
                            Text("Achievements")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal)
                    
                    if !profileController.getAchievements().isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(profileController.getAchievements()) { achievement in
                                    VStack(spacing: 4) {
                                        Image(systemName: achievement.iconName)
                                            .font(.title2)
                                            .foregroundColor(.yellow)
                                        Text(achievement.title)
                                            .font(.caption)
                                            .lineLimit(1)
                                    }
                                    .padding(8)
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.96, green: 0.88, blue: 0.90))
        .cornerRadius(15)
    }
}

// MARK: - Reusable Button Components
struct ProfileButton: View {
    var icon: String
    var label: String
    var color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.white)
                .padding()
                .background(color)
                .clipShape(Circle())

            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

struct FooterButton: View {
    var icon: String
    var label: String
    var color: Color

    var body: some View {
        VStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(label)
                    .fontWeight(.semibold)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.3))
            .foregroundColor(color)
            .cornerRadius(12)
        }
    }
}

// MARK: - Updated Modal Views Following OOP Principles
// MARK: - AvatarCustomizationView Refactor
struct AvatarCustomizationView: View {
    @Binding var avatarImage: UIImage?
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var isImageSaved = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Choose Your Avatar")
                    .font(.title)
                    .padding()

                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .foregroundColor(.gray)
                }

                Button(action: {
                    showImagePicker = true
                }) {
                    Text("Select Avatar")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }

                if selectedImage != nil {
                    Button(action: {
                        saveAvatarImage()
                    }) {
                        Text("Save Avatar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }

                    if isImageSaved {
                        Text("Avatar saved successfully!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Customize Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(selectedImage: $selectedImage)
            }
        }
    }

    private func saveAvatarImage() {
        if let selectedImage = selectedImage {
            avatarImage = selectedImage
            isImageSaved = true
        }
    }
}

struct ThemePickerView: View {
    @Binding var selectedTheme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager

    // Preview state to show the currently selected/previewed theme
    @State private var previewTheme: AppTheme = .default

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                // Live preview area
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview")
                        .font(.headline)
                        .padding(.leading)

                    HStack(spacing: 12) {
                        // Larger color indicators
                        Circle()
                            .fill(chosenColor(previewTheme))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(Color(hex: previewTheme.colors.secondary))
                            .frame(width: 36, height: 36)
                        Circle()
                            .fill(Color(hex: previewTheme.colors.background))
                            .frame(width: 36, height: 36)

                        Spacer()

                        // Hex label for primary
                        Text("Primary: \(previewTheme.colors.primary)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)

                    // Sample card that shows how primary/secondary/background apply together
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: previewTheme.colors.background))
                        .overlay(
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Sample Title")
                                        .font(.headline)
                                        .foregroundColor(chosenColor(previewTheme))
                                    Text("Secondary text")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: previewTheme.colors.secondary))
                                }
                                Spacer()
                                Circle()
                                    .stroke(chosenColor(previewTheme), lineWidth: 3)
                                    .frame(width: 36, height: 36)
                            }
                            .padding()
                        )
                        .frame(height: 80)
                        .padding([.horizontal, .bottom])
                }

                List {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(theme.rawValue)
                                    .font(.headline)
                                Text("Primary: \(theme.colors.primary)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()

                            // Theme color preview
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(Color(hex: theme.colors.primary))
                                    .frame(width: 20, height: 20)
                                Circle()
                                    .fill(Color(hex: theme.colors.secondary))
                                    .frame(width: 20, height: 20)
                                Circle()
                                    .fill(Color(hex: theme.colors.background))
                                    .frame(width: 20, height: 20)
                            }

                            if theme == selectedTheme {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // update persisted selection and live preview
                            selectedTheme = theme
                            previewTheme = theme
                            // apply globally
                            themeManager.apply(theme)
                        }
                        .onHover { _ in
                            // on macOS hover could preview — ignore on iOS; kept lightweight
                        }
                        .onLongPressGesture(minimumDuration: 0.15) {
                            // quick preview without committing
                            previewTheme = theme
                        }
                    }
                }
            }
            .navigationTitle("Choose Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // initialize preview to current selection when opened
                previewTheme = selectedTheme
            }
        }
    }

    // Helper that returns the primary Color for a given theme
    private func chosenColor(_ theme: AppTheme) -> Color {
        return Color.init(hex: theme.colors.primary)
    }

    // Helper that returns hex string for a given theme's primary (if you need it elsewhere)
    private func chosenColorHex(_ theme: AppTheme) -> String {
        return theme.colors.primary
    }
}

// MARK: - Placeholder Views for Features
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1

        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                return
            }

            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.selectedImage = image as? UIImage
                }
            }
        }
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.size.width
        let height = rect.size.height

        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(to: CGPoint(x: 0, y: height / 4),
                      control1: CGPoint(x: width / 4, y: height),
                      control2: CGPoint(x: 0, y: height * 3 / 4))
        path.addArc(center: CGPoint(x: width / 4, y: height / 4),
                    radius: width / 4,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        path.addArc(center: CGPoint(x: width * 3 / 4, y: height / 4),
                    radius: width / 4,
                    startAngle: Angle(degrees: 180),
                    endAngle: Angle(degrees: 0),
                    clockwise: false)
        path.addCurve(to: CGPoint(x: width / 2, y: height),
                      control1: CGPoint(x: width, y: height * 3 / 4),
                      control2: CGPoint(x: width * 3 / 4, y: height))

        return path
    }
}

struct ProfileTabView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileTabView()
            .environmentObject(ThemeManager())
    }
}
