import SwiftUI

public struct AccountScreen: View {
    @Bindable public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Header
                HStack {
                    Text(store.userProfile.userName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button(action: { store.navigateTo(.editProfile) }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }

                        Button(action: { store.navigateTo(.settings) }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }

                        Button(action: { store.navigateTo(.paywall) }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(AppTheme.navyCard))
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // 2. Profile Card
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentYellow)
                            .frame(width: 64, height: 64)

                        Image(systemName: "person.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.black)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(store.userProfile.userName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        Text("\(store.userProfile.followersCount) Followers   \(store.userProfile.followingCount) Following")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)

                        if !store.userProfile.userBio.isEmpty {
                            Text(store.userProfile.userBio)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AppTheme.navyCard)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.navyBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)

                // 3. VIP Membership Banner
                Button(action: { store.navigateTo(.paywall) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.brandPinkCyan)
                                .frame(width: 44, height: 44)
                            Image(systemName: "crown.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Upgrade to VIP")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)
                            Text("Unlock 15,000+ sounds, presets & effects")
                                .font(.system(size: 11))
                                .foregroundColor(AppTheme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.accentCyan)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(hex: "#1A1535"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color(hex: "#FF2A85").opacity(0.4), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)

                // 4. User's Tracks & Activity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("My Beat Creations (\(store.recordings.count))")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.horizontal, 16)

                    if store.recordings.isEmpty {
                        Text("You haven't recorded any beats yet. Go to Pad Player and hit Record to build your discography!")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                    } else {
                        ForEach(store.recordings) { rec in
                            HStack {
                                Image(systemName: "waveform")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.accentCyan)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(AppTheme.navyCardElevated))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rec.title)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Text("\(rec.durationFormatted) • \(rec.packName)")
                                        .font(.system(size: 11))
                                        .foregroundColor(AppTheme.textSecondary)
                                }

                                Spacer()

                                Button(action: { store.shareRecording(rec) }) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(AppTheme.accentYellow)
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(AppTheme.navyCard)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(AppTheme.navyBorder, lineWidth: 1)
                                    )
                            )
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 100)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

// -------------------------------------------------------------
// EDIT PROFILE SCREEN
// -------------------------------------------------------------
public struct EditProfileScreen: View {
    @Bindable public var store: DrumPadsStore
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var link: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
        _name = State(initialValue: store.userProfile.userName)
        _bio = State(initialValue: store.userProfile.userBio)
        _link = State(initialValue: store.userProfile.userLink)
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { store.navigateTo(.main) }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                    }

                    Spacer()

                    Text("Edit profile")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Spacer()

                    Button(action: {
                        store.updateProfile(name: name, bio: bio, link: link)
                        store.navigateTo(.main)
                    }) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.accentCyan)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Avatar
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(AppTheme.accentYellow)
                        .frame(width: 90, height: 90)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.black)
                        )

                    Circle()
                        .fill(AppTheme.navyCardElevated)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                        )
                        .overlay(Circle().stroke(AppTheme.navyBackground, lineWidth: 2))
                }
                .padding(.top, 12)

                // Fields
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Name")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Your Name", text: $name)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.navyCard)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.navyBorder, lineWidth: 1))
                            )
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("A few words about yourself")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("Bio", text: $bio)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.navyCard)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.navyBorder, lineWidth: 1))
                            )
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Social / Instagram link")
                            .font(.system(size: 12))
                            .foregroundColor(AppTheme.textSecondary)
                        TextField("https://...", text: $link)
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.navyCard)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.navyBorder, lineWidth: 1))
                            )
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }
}

