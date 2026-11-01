import Foundation
import SwiftUI

public enum Genre: String, CaseIterable, Identifiable, Sendable {
    case all = "All"
    case edm = "EDM"
    case trap = "Trap"
    case hiphop = "Hip-Hop"
    case house = "House"
    case dubstep = "Dubstep"
    case phonk = "Phonk"
    case lofi = "Lo-Fi"
    case synthwave = "Synthwave"
    case dnb = "Drum & Bass"
    case techno = "Techno"
    case rnb = "R&B"
    case pop = "Pop"

    public var id: String { rawValue }
}

public struct SoundPackItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let genre: String
    public let isPro: Bool
    public let colorHex: String
    public let bpm: Int
    public let gradientHexes: [String]
    public let author: String
    public let downloads: String

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "Drum Pads 24",
        genre: String,
        isPro: Bool = false,
        colorHex: String = "#FF416C",
        bpm: Int = 120,
        gradientHexes: [String] = ["#FF416C", "#FF4B2B"],
        author: String = "Drum Pads 24 Crew",
        downloads: String = "50K+"
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.genre = genre
        self.isPro = isPro
        self.colorHex = colorHex
        self.bpm = bpm
        self.gradientHexes = gradientHexes
        self.author = author
        self.downloads = downloads
    }

    public var gradientColors: [Color] {
        gradientHexes.map { Color(hex: $0) }
    }
}

public enum SoundPackCatalog {
    public static let featuredStories: [SoundPackItem] = [
        SoundPackItem(title: "Kilimanjaro", subtitle: "Afro House & Drums", genre: "House", bpm: 124, gradientHexes: ["#FF9966", "#FF5E62"]),
        SoundPackItem(title: "Rain Dance", subtitle: "Hypnotic Techno", genre: "Techno", bpm: 130, gradientHexes: ["#2193B0", "#6DD5ED"]),
        SoundPackItem(title: "Equilibrium", subtitle: "Neurofunk & DnB", genre: "Drum & Bass", bpm: 174, gradientHexes: ["#8A2387", "#E94057"]),
        SoundPackItem(title: "Medium Rare", subtitle: "Crispy Boom Bap", genre: "Hip-Hop", bpm: 90, gradientHexes: ["#F12711", "#F5AF19"]),
        SoundPackItem(title: "Heavenly", subtitle: "Modern Trap Soul", genre: "R&B", bpm: 110, gradientHexes: ["#00C9FF", "#92FE9D"]),
        SoundPackItem(title: "Cyber Drift", subtitle: "High Speed Phonk", genre: "Phonk", bpm: 140, gradientHexes: ["#4776E6", "#8E54E9"])
    ]

    public static let newReleases: [SoundPackItem] = [
        SoundPackItem(title: "You Are Dead", subtitle: "Heavy Dubstep Drop", genre: "Dubstep", isPro: true, bpm: 145, gradientHexes: ["#F857A6", "#FF5858"]),
        SoundPackItem(title: "Bleed", subtitle: "Riddim & Heavy Bass", genre: "Dubstep", isPro: true, bpm: 150, gradientHexes: ["#FF0844", "#FFB199"]),
        SoundPackItem(title: "Zombie Land", subtitle: "Industrial Hardstyle", genre: "EDM", isPro: false, bpm: 150, gradientHexes: ["#11998E", "#38EF7D"]),
        SoundPackItem(title: "Retro City", subtitle: "80s Synth Nostalgia", genre: "Synthwave", isPro: false, bpm: 118, gradientHexes: ["#5F2C82", "#49A09D"]),
        SoundPackItem(title: "Hyphy", subtitle: "West Coast 808s", genre: "Trap", isPro: false, bpm: 138, gradientHexes: ["#E94057", "#F27121"]),
        SoundPackItem(title: "Neon Pulse 24", subtitle: "Official Starter Kit", genre: "EDM", isPro: false, bpm: 120, gradientHexes: ["#FF2A85", "#00DFD8"]),
        SoundPackItem(title: "Lo-Fi Sunset", subtitle: "Tape Warble & Rhodes", genre: "Lo-Fi", isPro: false, bpm: 82, gradientHexes: ["#FA709A", "#FEE140"]),
        SoundPackItem(title: "Dark Matter", subtitle: "Atmospheric Techno", genre: "Techno", isPro: true, bpm: 132, gradientHexes: ["#30CFD0", "#330867"])
    ]

    public static let upcomingPacks = [
        "Cocoon (Deep Minimal)",
        "Dancing (Vocal Tech House)",
        "Dark Matter (Hypnotic)",
        "Sunset Chill (Organic Downtempo)"
    ]
}

