import SwiftUI

public struct PaywallScreen: View {
    public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ZStack {
            AppTheme.navyBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar (Close and Restore)
                HStack {
                    Button(action: { store.navigateTo(.main) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(AppTheme.navyCard))
                    }

                    Spacer()

                    Button(action: {
                        // Mock restore
                        store.navigateTo(.main)
                    }) {
                        Text("Restore")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                Spacer()

                // Center Showcase Graphic
                ZStack {
                    RoundedRectangle(cornerRadius: 32)
                        .fill(AppTheme.studioCardGradient)
                        .frame(width: 150, height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 32)
                                .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color(hex: "#EC4899").opacity(0.4), radius: 20)

                    Image(systemName: "music.quarternote.3")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                }

                Spacer().frame(height: 28)

                // Headline
                Text("All-in-one music studio")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(AppTheme.accentCyan)
                    .multilineTextAlignment(.center)

                Spacer().frame(height: 12)

                // Description
                Text("Obtain the Premium Pass and get access to the Drum Pads 24 library with 15 000+ premium sounds, all features including audio effects, and ad-free experience.")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 32)

                Spacer().frame(height: 24)

                // Pricing Info
                Text("3 days for free\nthen 47.000 ₫/week")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Spacer()

                // Bottom Continue CTA Button
                Button(action: {
                    store.userProfile.isProUser = true
                    store.navigateTo(.main)
                }) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 26)
                                .fill(AppTheme.brandPinkCyan)
                        )
                        .shadow(color: Color(hex: "#FF2A85").opacity(0.5), radius: 12)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

