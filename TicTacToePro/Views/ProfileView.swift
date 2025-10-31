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
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        Task { await saveAndDismiss() }
                    }
                }
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
    func saveAndDismiss() async {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            await MainActor.run { dismiss() }
            return
        }
        profileName = trimmed
        await multiplayerVM.updateUsername(trimmed)
        await MainActor.run { dismiss() }
    }
}

#Preview {
    ProfileView().environmentObject(MultiplayerViewModel.preview)
}



