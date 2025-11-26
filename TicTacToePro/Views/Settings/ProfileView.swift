//
//  ProfileView.swift
//  TicTacToePro
//
//  Created by Sunnatbek
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var multiplayerVM: MultiplayerViewModel
    
    @AppStorage("profileName") private var profileName: String = ""
    @FocusState private var isNameFocused: Bool
    
    // Error handling
    @State private var errorMessage: String?
    @State private var showError: Bool = false
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Premium background to match app style
                ZStack {
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.08, green: 0.08, blue: 0.10), Color(red: 0.11, green: 0.12, blue: 0.18), Color(red: 0.03, green: 0.04, blue: 0.06)]
                            : [Color(red: 0.98, green: 0.98, blue: 1.0), Color(red: 0.95, green: 0.96, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.98)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    Rectangle()
                        .fill(LinearGradient(colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.02 : 0.08),
                            Color.black.opacity(colorScheme == .dark ? 0.02 : 0.01)
                        ], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .blendMode(.overlay)
                        .opacity(0.6)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(
                                LinearGradient(colors: [.pink, .purple, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                        Text("Profile")
                            .font(.title.bold())
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 16)
                    
                    // Card with single name field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        HStack {
                            TextField("Your name", text: $profileName)
                                .textInputAutocapitalization(.words)
                                .disableAutocorrection(true)
                                .focused($isNameFocused)
                            if !profileName.isEmpty {
                                Button {
                                    profileName = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(LinearGradient(colors: [.purple.opacity(0.35), .blue.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                    }
                    .padding(16)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(LinearGradient(colors: [.pink.opacity(0.3), .purple.opacity(0.3)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                    )
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                
                // Loading overlay
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .navigationTitle("Profile")
#if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task { await saveAndDismiss() }
                    }
                    .disabled(isLoading)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .alert("Error", isPresented: $multiplayerVM.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(multiplayerVM.errorMessage ?? "Unknown error")
            }
        }
        .onAppear {
            if profileName.isEmpty, let existing = multiplayerVM.currentPlayer?.username, !existing.isEmpty {
                profileName = existing
            }
            isNameFocused = true
        }
    }
}

private extension ProfileView {
    @MainActor
    func saveAndDismiss() async {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validation
        guard !trimmed.isEmpty else {
            showErrorAlert(message: "Name cannot be empty")
            return
        }
        
        guard trimmed.count <= 30 else {
            showErrorAlert(message: "Name must be 30 characters or less")
            return
        }
        
        // Check for invalid characters (only letters, numbers, spaces, and common punctuation)
        let allowedCharacterSet = CharacterSet.letters
            .union(.whitespaces)
            .union(.decimalDigits)
            .union(CharacterSet(charactersIn: ".-_"))
        let invalidCharacters = trimmed.unicodeScalars.first { !allowedCharacterSet.contains($0) }
        guard invalidCharacters == nil else {
            showErrorAlert(message: "Name contains invalid characters. Use only letters, numbers, spaces, and basic punctuation (.-_).")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        profileName = trimmed
        await multiplayerVM.updateUsername(trimmed)
        
        // Check if MultiplayerViewModel reported an error
        if multiplayerVM.showError {
            // Error will be shown by the alert that binds to multiplayerVM.showError
            isLoading = false
            return
        }
        
        // Success - dismiss after a brief delay to show success state
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        isLoading = false
        dismiss()
    }
    
    func showErrorAlert(message: String) {
        errorMessage = message
        showError = true
    }
}

#Preview {
    ProfileView().environmentObject(MultiplayerViewModel.preview)
}
