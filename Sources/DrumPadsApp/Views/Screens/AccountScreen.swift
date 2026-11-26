import SwiftUI

public struct AccountScreen: View {
    public var store: DrumPadsStore

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Account")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { store.navigateTo(.settings) }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(AppTheme.navyCard))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)

                // Profile Card
                VStack(spacing: 14) {
                    Circle()
                        .fill(AppTheme.studioCardGradient)
                        .frame(width: 78, height: 78)
                        .overlay(
                            Text(String(store.userProfile.userName.prefix(2)).uppercased())
                                .font(.system(size: 26, weight: .black))
                                .foregroundColor(.white)
                        )

                    Text(store.userProfile.userName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text(store.userProfile.userBio)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 26) {
                        statCol("\(store.recordings.count)", "Tracks")
                        statCol("\(store.customPacks.count)", "Custom Kits")
                        statCol("\(store.userProfile.followersCount)", "Followers")
                        statCol("\(store.userProfile.followingCount)", "Following")
                    }
                    .padding(.top, 4)

                    Button(action: { store.navigateTo(.editProfile) }) {
                        Text("Edit Profile")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(AppTheme.accentYellow))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 22).fill(AppTheme.navyCard))
                .padding(.horizontal, 16)

                // Action Links
                VStack(spacing: 10) {
                    accountRow(icon: "waveform", title: "My WAV & Video Recordings", badge: "\(store.recordings.count)") {
                        store.navigateTo(.recordings)
                    }
                    accountRow(icon: "square.grid.2x2.fill", title: "Create Custom Sound Pack", badge: nil) {
                        store.navigateTo(.projectEditor)
                    }
                    accountRow(icon: "clock.fill", title: "Recently Played Kits", badge: "\(store.recentlyUsedPacks.count)") {
                        store.navigateTo(.recentlyUsed)
                    }
                    accountRow(icon: "slider.horizontal.3", title: "Audio Engine & Latency Settings", badge: nil) {
                        store.navigateTo(.settings)
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 140)
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
    }

    private func statCol(_ val: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(val)
                .font(.system(size: 17, weight: .black))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppTheme.textSecondary)
        }
    }

    private func accountRow(icon: String, title: String, badge: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.accentYellow)
                    .frame(width: 30)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppTheme.accentCyan))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.navyCard))
        }
        .buttonStyle(.plain)
    }
}

public struct EditProfileScreen: View {
    public var store: DrumPadsStore
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var link: String = ""

    public init(store: DrumPadsStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: { store.navigateTo(.main) }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Edit Profile")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Save") {
                    store.updateUserProfile(name: name, bio: bio, link: link)
                    store.navigateTo(.main)
                }
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppTheme.accentYellow)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            VStack(alignment: .leading, spacing: 12) {
                Text("DISPLAY NAME").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.textSecondary)
                TextField("Name", text: $name)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
                    .foregroundColor(.white)

                Text("BIO").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.textSecondary)
                TextField("Bio", text: $bio)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
                    .foregroundColor(.white)

                Text("SOCIAL LINK").font(.system(size: 11, weight: .bold)).foregroundColor(AppTheme.textSecondary)
                TextField("Link", text: $link)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppTheme.navyCard))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)

            Spacer()
        }
        .background(AppTheme.navyBackground.ignoresSafeArea())
        .onAppear {
            name = store.userProfile.userName
            bio = store.userProfile.userBio
            link = store.userProfile.userLink
        }
    }
}
