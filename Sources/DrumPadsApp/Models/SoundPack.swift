import SwiftUI

public enum MusicGenre: String, CaseIterable, Codable, Sendable {
    case all = "All Genres"
    case edm = "EDM"
    case trap = "Trap"
    case hipHop = "Hip-Hop"
    case house = "House"
    case dubstep = "Dubstep"
    case phonk = "Phonk"
    case lofi = "Lo-Fi"
    case synthwave = "Synthwave"
    case dnb = "Drum & Bass"
    case techno = "Techno"
    case rnb = "R&B"
    case pop = "Pop"

    public var displayName: String { rawValue }
}

public struct SoundPack: Identifiable, Hashable, Codable, Sendable {
    public let id: String
    public var title: String
    public var subtitle: String
    public var genre: MusicGenre
    public var author: String
    public var bpm: Int
    public var gradientHexes: [String]
    public var isNew: Bool
    public var isCustom: Bool
    public var descriptionText: String

    public init(
        id: String,
        title: String,
        subtitle: String,
        genre: MusicGenre,
        author: String = "DP24 Studio",
        bpm: Int = 128,
        gradientHexes: [String],
        isNew: Bool = false,
        isCustom: Bool = false,
        descriptionText: String = "24 studio-tuned pads ready for live finger drumming."
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.genre = genre
        self.author = author
        self.bpm = bpm
        self.gradientHexes = gradientHexes
        self.isNew = isNew
        self.isCustom = isCustom
        self.descriptionText = descriptionText
    }

    public var gradientColors: [Color] {
        gradientHexes.map { Color(hex: $0) }
    }
}

public enum SoundPackCatalog {
    public static let featuredStories: [SoundPack] = [
        SoundPack(id: "trap_god", title: "TRAP GOD", subtitle: "Hard 808s & Rolling Hats", genre: .trap, author: "808 Mafia Crew", bpm: 140, gradientHexes: ["#F97316", "#EF4444", "#8B5CF6"], isNew: true),
        SoundPack(id: "phonk_drift", title: "PHONK DRIFT", subtitle: "Cowbells & Memphis 808", genre: .phonk, author: "Drift King", bpm: 132, gradientHexes: ["#EC4899", "#9333EA", "#1E1B4B"], isNew: true),
        SoundPack(id: "edm_festival", title: "FESTIVAL EDM", subtitle: "Big Room Drops & Plucks", genre: .edm, author: "Paul Lipnyagov", bpm: 128, gradientHexes: ["#3B82F6", "#06B6D4", "#10B981"], isNew: true),
        SoundPack(id: "neon_synthwave", title: "RETRO WAVE", subtitle: "80s Analog Brass & Arps", genre: .synthwave, author: "Neon Rider", bpm: 112, gradientHexes: ["#D946EF", "#F59E0B", "#7C3AED"], isNew: false),
        SoundPack(id: "lofi_rain", title: "RAINY LO-FI", subtitle: "Dusty Keys & Vinyl Crackle", genre: .lofi, author: "Chillhop Lab", bpm: 84, gradientHexes: ["#06B6D4", "#3B82F6", "#6366F1"], isNew: false),
        SoundPack(id: "wobble_king", title: "DUBSTEP WOBBLE", subtitle: "Heavy FM Growls & Subs", genre: .dubstep, author: "Bassline Syndicate", bpm: 140, gradientHexes: ["#7C3AED", "#EC4899", "#F43F5E"], isNew: true)
    ]

    public static let newReleases: [SoundPack] = [
        SoundPack(id: "club_house", title: "DEEP HOUSE", subtitle: "Punchy 4x4 & Organ Bass", genre: .house, author: "Ibiza Nights", bpm: 124, gradientHexes: ["#F59E0B", "#EC4899"], isNew: true),
        SoundPack(id: "underground_hiphop", title: "BOOM BAP", subtitle: "Golden Era Breakbeats", genre: .hipHop, author: "DJ Scratch", bpm: 92, gradientHexes: ["#10B981", "#3B82F6"], isNew: true),
        SoundPack(id: "dnb_neuro", title: "NEURO DNB", subtitle: "174 BPM Reese & Amen", genre: .dnb, author: "UK Junglist", bpm: 174, gradientHexes: ["#EF4444", "#F59E0B"], isNew: true),
        SoundPack(id: "berlin_techno", title: "BERLIN TECHNO", subtitle: "Industrial 303 & Rumble", genre: .techno, author: "Kraft Room", bpm: 136, gradientHexes: ["#4B5563", "#111827"], isNew: false),
        SoundPack(id: "velvet_rnb", title: "VELVET R&B", subtitle: "Silky 7th Chords & Snaps", genre: .rnb, author: "Soul Collective", bpm: 96, gradientHexes: ["#DB2777", "#7C3AED"], isNew: false),
        SoundPack(id: "starlight_pop", title: "STARLIGHT POP", subtitle: "Crisp Synths & Vocal Chops", genre: .pop, author: "Hit Factory", bpm: 118, gradientHexes: ["#38BDF8", "#818CF8"], isNew: true),
        SoundPack(id: "cyber_phonk", title: "CYBER PHONK", subtitle: "Distorted 808 Cowbell", genre: .phonk, author: "Night Runner", bpm: 138, gradientHexes: ["#F43F5E", "#7C3AED"], isNew: true),
        SoundPack(id: "future_bass", title: "FUTURE BASS", subtitle: "Supersaw Stacks & Snare", genre: .edm, author: "Prism Beats", bpm: 150, gradientHexes: ["#06B6D4", "#8B5CF6"], isNew: false),
        SoundPack(id: "acid_rave", title: "ACID RAVE 909", subtitle: "Resonant Squelch & Claps", genre: .techno, author: "Warehouse 24", bpm: 134, gradientHexes: ["#A3E635", "#059669"], isNew: false),
        SoundPack(id: "drill_night", title: "UK DRILL", subtitle: "Sliding 808s & Counter Snares", genre: .trap, author: "South London", bpm: 142, gradientHexes: ["#0EA5E9", "#1E293B"], isNew: true),
        SoundPack(id: "midnight_chill", title: "MIDNIGHT JAZZ", subtitle: "Warm Rhodes & Brush Kits", genre: .lofi, author: "Moonlight Tape", bpm: 78, gradientHexes: ["#6366F1", "#1E1B4B"], isNew: false),
        SoundPack(id: "liquid_dnb", title: "LIQUID SKIES", subtitle: "Rolling Breaks & Atmospheric", genre: .dnb, author: "Hospital Vibes", bpm: 172, gradientHexes: ["#00DFD8", "#007CF0"], isNew: false)
    ]

    public static var allBuiltInPacks: [SoundPack] {
        featuredStories + newReleases
    }

    public static func findPack(byIdOrTitle query: String) -> SoundPack? {
        allBuiltInPacks.first {
            $0.id.caseInsensitiveCompare(query) == .orderedSame ||
            $0.title.caseInsensitiveCompare(query) == .orderedSame
        }
    }

    public static func buildPads(for genre: MusicGenre) -> [Pad] {
        let drums: [String]
        let basses: [String]
        let melodies: [String]
        let fxs: [String]

        switch genre {
        case .phonk:
            drums = ["Phonk Kick", "Dist 808", "Memphis Snr", "Rim Shot", "Closed Hat", "Open Hat"]
            basses = ["808 Reese C", "808 Glide D", "Sub Drop E", "Growl F#", "Saw Sub A", "Dark Bass"]
            melodies = ["Cowbell C4", "Cowbell D#4", "Cowbell F4", "Cowbell G4", "Cowbell A#4", "Bell Lead C5"]
            fxs = ["Drift Tire", "MemphisVox", "Riser Dark", "Gun Cock", "Tape Stop", "Hey Chant"]
        case .trap:
            drums = ["Trap 808 K", "Hard Kick", "Clap Crisp", "Snare Snap", "Roll Hat", "Open Hat"]
            basses = ["808 Boom C", "808 Glide F", "Sub G", "808 Dist C", "Pluck Bass", "Deep Sub"]
            melodies = ["Dark Flute", "Trap Bell C", "Piano Minor", "Pluck D", "Choir Hit", "Arp Minor"]
            fxs = ["Hey! Vocal", "Yeah! Vox", "Laser Zapp", "Crash Cym", "Reverse FX", "Siren Hit"]
        case .dubstep:
            drums = ["Heavy Kick", "Punch Kick", "Dub Snare", "Laser Snr", "Metal Hat", "Ride Cym"]
            basses = ["Wobble 1/4", "Wobble 1/8", "FM Growl", "Yoi Bass", "Sub Drop", "Screech B"]
            melodies = ["Saw Lead", "Arp Cyber", "Pad Dark", "Pluck Det", "Stab Cord", "Seq Arp"]
            fxs = ["Riser 4Bar", "Downlifter", "Impact Boom", "Glitch FX", "Vocal Cut", "Drop Signal"]
        case .lofi:
            drums = ["Dusty Kick", "Warm Thump", "Brush Snr", "Vinyl Clap", "Shaker Soft", "Hat Lazy"]
            basses = ["Upright C", "Warm Sub E", "Muted Bass", "Rhodes Low", "Fretless G", "Sub Cushion"]
            melodies = ["Rhodes Maj7", "Rhodes Min9", "Vinyl Keys", "Guitar Jazz", "Music Box", "Flute Airy"]
            fxs = ["Rain Amb", "Vinyl Crk", "Tape Hiss", "Bell Wind", "Soft Breath", "Cassette FX"]
        case .house:
            drums = ["4x4 Kick", "Club Kick", "House Clap", "Snare Tight", "Offbeat OH", "Tambourine"]
            basses = ["M1 Organ C", "M1 Organ F", "Donk Bass", "Sub House", "Funk Pluck", "Slap Bass"]
            melodies = ["Piano Korg", "House Chord", "Stab Minor", "Brass Hit", "Pluck Arp", "Lead Warm"]
            fxs = ["Noise Sweep", "White Riser", "Vox Groove", "Crash Gate", "Clap Reverb", "Drop FX"]
        case .synthwave:
            drums = ["Gated Kick", "Linn Kick", "Gated Snare", "Simmons Tom", "Crisp Hat", "Splash Cym"]
            basses = ["Juno Arp C", "Saw 8th F", "Analog G", "Sub PWM", "Pulse A", "Octave Bass"]
            melodies = ["Brass 80s C", "Polysynth", "Lead Solo", "Pad Horizon", "Bell DX7", "Arp Neon"]
            fxs = ["Retro Boom", "Laser Tom", "Sweep Analog", "Vocoder FX", "Tape Rewind", "Synth Riser"]
        case .dnb:
            drums = ["Punch Kick", "Thud Kick", "Break Snare", "Ghost Snare", "Ticky Hat", "Amen Ride"]
            basses = ["Reese C", "Neuro Morph", "Sub Slide", "Wobble Fast", "Foghorn", "Acid Sub"]
            melodies = ["Atmos Pad", "Liquid Pno", "Chord Lush", "Pluck Crisp", "Arp Fast", "Stab Brass"]
            fxs = ["Breaker FX", "Amen Chop", "Sweep Fast", "Crash Wide", "Vocal Echo", "Laser Hit"]
        case .techno:
            drums = ["909 Kick", "Rumble Kick", "909 Clap", "Crisp Rim", "909 Hat Cl", "909 Hat Op"]
            basses = ["303 Acid C", "303 Squelch", "Rumble Sub", "Industrial", "FM Perc B", "Drone Low"]
            melodies = ["Stab Chord", "Rave Horn", "Hypno Arp", "Bleep C5", "Metal Bell", "Raw Saw"]
            fxs = ["Noise Gate", "Steam Hiss", "Rev Crash", "Siren Techno", "Modular Zap", "Clock Tick"]
        case .hipHop:
            drums = ["MPC Kick", "Vinyl Kick", "Boom Snare", "Rim Crack", "Swing Hat", "Crash Dust"]
            basses = ["Moog Sub C", "808 Round", "Finger Bass", "Slap Low", "Synth Hum", "Deep Pluck"]
            melodies = ["Jazz Chop", "Rhodes Warm", "Sax Stab", "Strings Hit", "Bell Rhodes", "Guitar Lick"]
            fxs = ["Scratch 1", "Scratch 2", "Yo! Vox", "Check It!", "Vinyl Stop", "Air Horn"]
        case .rnb:
            drums = ["Warm Kick", "808 Soft", "Finger Snap", "Dry Snare", "Velvet Hat", "Shaker L/R"]
            basses = ["Sine Glide", "Moog Warm", "R&B Sub F", "Slide Bass", "Deep Warm", "Bass Pluck"]
            melodies = ["Min9 Chord", "Maj7 Lush", "Bell Pluck", "E-Piano", "Pad Silky", "Harp Sweep"]
            fxs = ["Finger FX", "Breath Vox", "Ooh Chop", "Rev Bell", "Wind Chime", "Riser Soft"]
        case .pop:
            drums = ["Pop Kick", "Punch Thump", "Crisp Clap", "Tight Snare", "Bright Hat", "Open Hat"]
            basses = ["Future Sub", "Pluck Bass", "Funky Synth", "Pick Bass", "Octave Sub", "Bounce Low"]
            melodies = ["Supersaw C", "Marimba Pop", "Piano Bright", "Guitar Funk", "Pluck Lead", "Bell Spark"]
            fxs = ["Hey! Pop", "Oh! Vox", "Drop Sweep", "Down Hit", "Impact Cym", "Sparkle FX"]
        case .edm, .all:
            drums = ["Big Kick", "Punch Kick", "EDM Clap", "Snare Build", "Closed Hat", "Open Hat"]
            basses = ["Bigroom C", "Electro D", "Pluck E", "Slap F#", "Saw G", "Sub Drop"]
            melodies = ["Supersaw C", "Pluck D", "Festival E", "Piano Chord", "Arp Lead G", "Stab C5"]
            fxs = ["Riser Sweep", "White Noise", "Crash Wide", "Laser Shot", "Hey Chant", "Drop Oh!"]
        }

        var result: [Pad] = []
        let drumColors = ["#E53935", "#EF4444", "#FF3B30", "#E53935", "#FF5252", "#D32F2F"]
        let bassColors = ["#8E24AA", "#9C27B0", "#7B1FA2", "#AB47BC", "#6A1B9A", "#9D00FF"]
        let melodyColors = ["#00897B", "#00ACC1", "#00E5FF", "#26A69A", "#00B0FF", "#00DFD8"]
        let fxColors = ["#FB8C00", "#FF9800", "#FFA726", "#F57C00", "#FFD600", "#FF7A00"]

        let genreKey = genre.rawValue.lowercased().replacingOccurrences(of: " ", with: "_").replacingOccurrences(of: "&", with: "and")

        for i in 0..<6 {
            result.append(Pad(
                index: i,
                name: drums[i],
                group: .drum,
                sampleId: "\(genreKey)_drum_\(i)",
                sampleFile: "starter/samples/\(genreKey)_drum_\(i).wav",
                colorHex: drumColors[i],
                chokeGroup: (i >= 4) ? 1 : 0
            ))
        }
        for i in 0..<6 {
            result.append(Pad(
                index: 6 + i,
                name: basses[i],
                group: .bass,
                sampleId: "\(genreKey)_bass_\(i)",
                sampleFile: "starter/samples/\(genreKey)_bass_\(i).wav",
                colorHex: bassColors[i],
                chokeGroup: 2
            ))
        }
        for i in 0..<6 {
            result.append(Pad(
                index: 12 + i,
                name: melodies[i],
                group: .melody,
                sampleId: "\(genreKey)_melody_\(i)",
                sampleFile: "starter/samples/\(genreKey)_melody_\(i).wav",
                colorHex: melodyColors[i],
                chokeGroup: 0
            ))
        }
        for i in 0..<6 {
            result.append(Pad(
                index: 18 + i,
                name: fxs[i],
                group: .fx,
                sampleId: "\(genreKey)_fx_\(i)",
                sampleFile: "starter/samples/\(genreKey)_fx_\(i).wav",
                colorHex: fxColors[i],
                chokeGroup: 0
            ))
        }
        return result
    }
}
