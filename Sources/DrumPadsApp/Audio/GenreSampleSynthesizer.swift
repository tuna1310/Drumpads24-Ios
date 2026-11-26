import Foundation

public enum GenreSampleSynthesizer {
    public static func generatePackSamples(
        genre: MusicGenre,
        packId: String = "",
        sampleRate: Double = 44100.0
    ) -> [Int: [Float]] {
        let table = [0, -3, 2, -5, 4, 7, -2, 5, 1, -4, 3, 6]
        let semitones = packId.isEmpty ? 0 : table[abs(packId.hashValue) % table.count]
        let keyRatio = pow(2.0, Double(semitones) / 12.0)
        var result: [Int: [Float]] = [:]
        for padIndex in 0..<24 {
            result[padIndex] = synthesizePadSample(
                padIndex: padIndex,
                genre: genre,
                keyRatio: keyRatio,
                sampleRate: sampleRate
            )
        }
        return result
    }

    public static func synthesizePadSample(
        padIndex: Int,
        genre: MusicGenre,
        keyRatio: Double = 1.0,
        sampleRate: Double = 44100.0
    ) -> [Float] {
        let localIdx = padIndex % 6
        switch padIndex {
        case 0...5:
            return synthDrum(localIdx: localIdx, genre: genre, sr: sampleRate)
        case 6...11:
            return synthBass(localIdx: localIdx, genre: genre, keyRatio: keyRatio, sr: sampleRate)
        case 12...17:
            return synthMelody(localIdx: localIdx, genre: genre, keyRatio: keyRatio, sr: sampleRate)
        default:
            return synthFx(localIdx: localIdx, genre: genre, sr: sampleRate)
        }
    }

    private static func synthDrum(localIdx: Int, genre: MusicGenre, sr: Double) -> [Float] {
        switch localIdx {
        case 0, 1: // Kick
            let dur = (genre == .trap || genre == .phonk) ? 0.58 : 0.40
            let n = Int(sr * dur)
            var out = [Float](repeating: 0, count: n)
            let startFreq = (localIdx == 0) ? 165.0 : 125.0
            let endFreq = (genre == .trap || genre == .phonk) ? 42.0 : 48.0
            let drive = (genre == .phonk || genre == .techno || genre == .dubstep) ? 1.8 : 1.2
            var phase = 0.0
            for i in 0..<n {
                let t = Double(i) / sr
                let freq = endFreq + (startFreq - endFreq) * exp(-t * 26.0)
                phase += 2.0 * .pi * freq / sr
                let env = exp(-t * ((genre == .trap || genre == .phonk) ? 4.2 : 7.0))
                let click = exp(-t * 140.0) * 0.45
                out[i] = Float(tanh((sin(phase) * env + click) * drive) * 0.9)
            }
            return out

        case 2, 3: // Snare / Clap
            let dur = (genre == .dubstep || genre == .synthwave) ? 0.42 : 0.28
            let n = Int(sr * dur)
            var out = [Float](repeating: 0, count: n)
            var seed: UInt64 = UInt64(localIdx * 1337 + 42)
            let bodyFreq = (localIdx == 2) ? 185.0 : 220.0
            for i in 0..<n {
                let t = Double(i) / sr
                seed = (seed &* 6364136223846793005) &+ 1
                let noise = (Double(Int64(bitPattern: seed >> 1) & 0x7FFF_FFFF) / Double(0x7FFF_FFFF)) * 2.0 - 1.0
                let snapEnv = (genre == .lofi) ? exp(-t * 22.0) : exp(-t * 14.0)
                let bodyEnv = exp(-t * 24.0)
                let body = sin(2.0 * .pi * bodyFreq * t) * bodyEnv * 0.55
                let lofiBit = (genre == .lofi && i % 2 == 1) ? Double(out[i - 1]) : (noise * snapEnv * 0.65 + body)
                out[i] = Float(max(-1.0, min(1.0, lofiBit * 0.85)))
            }
            return out

        default: // Hats (4 = closed, 5 = open)
            let isClosed = (localIdx == 4)
            let dur = isClosed ? 0.09 : 0.36
            let n = Int(sr * dur)
            var out = [Float](repeating: 0, count: n)
            var seed: UInt64 = UInt64(localIdx * 9973 + 7)
            var prev = 0.0
            for i in 0..<n {
                let t = Double(i) / sr
                seed = (seed &* 6364136223846793005) &+ 1
                let noise = (Double(Int64(bitPattern: seed >> 1) & 0x7FFF_FFFF) / Double(0x7FFF_FFFF)) * 2.0 - 1.0
                let hp = noise - prev * 0.88
                prev = noise
                let metal = sin(2.0 * .pi * 8400.0 * t) * 0.25 + sin(2.0 * .pi * 5300.0 * t) * 0.2
                let env = exp(-t * (isClosed ? 42.0 : 9.0))
                out[i] = Float(max(-1.0, min(1.0, (hp * 0.7 + metal) * env * 0.72)))
            }
            return out
        }
    }

    private static func synthBass(localIdx: Int, genre: MusicGenre, keyRatio: Double, sr: Double) -> [Float] {
        let dur = (genre == .dubstep || genre == .dnb) ? 0.85 : 0.65
        let n = Int(sr * dur)
        var out = [Float](repeating: 0, count: n)
        let notes = [41.20, 46.25, 49.00, 55.00, 61.74, 65.41] // E1..C2
        let baseFreq = notes[localIdx % notes.count] * keyRatio

        for i in 0..<n {
            let t = Double(i) / sr
            let env = min(1.0, t / 0.01) * exp(-t * 2.5)
            let sample: Double
            switch genre {
            case .dubstep, .dnb:
                let lfo = 0.5 + 0.5 * sin(2.0 * .pi * (localIdx % 2 == 0 ? 4.0 : 6.0) * t)
                let carrier = sin(2.0 * .pi * baseFreq * t + 2.8 * lfo * sin(2.0 * .pi * baseFreq * 2.0 * t))
                sample = tanh(carrier * (1.5 + lfo * 1.4)) * env
            case .techno:
                let sq = sin(2.0 * .pi * baseFreq * t) > 0 ? 0.65 : -0.65
                let res = sin(2.0 * .pi * baseFreq * (2.0 + 4.0 * exp(-t * 10.0)) * t) * 0.45
                sample = tanh((sq + res) * 1.6) * env
            case .house:
                let f1 = sin(2.0 * .pi * baseFreq * t)
                let f2 = sin(2.0 * .pi * baseFreq * 2.0 * t) * 0.55
                let f3 = sin(2.0 * .pi * baseFreq * 3.0 * t) * 0.35 * exp(-t * 14.0)
                sample = (f1 + f2 + f3) * env * 0.55
            default: // Trap / Phonk / Hip-Hop 808
                let glide = baseFreq * (1.0 + 0.35 * exp(-t * 18.0))
                let sub = sin(2.0 * .pi * glide * t)
                let punch = sin(2.0 * .pi * glide * 2.0 * t) * exp(-t * 12.0) * 0.45
                sample = tanh((sub + punch) * (genre == .phonk ? 1.9 : 1.2)) * env
            }
            out[i] = Float(max(-1.0, min(1.0, sample * 0.85)))
        }
        return out
    }

    private static func synthMelody(localIdx: Int, genre: MusicGenre, keyRatio: Double, sr: Double) -> [Float] {
        let dur = 0.72
        let n = Int(sr * dur)
        var out = [Float](repeating: 0, count: n)
        let freqs = [261.63, 311.13, 349.23, 392.00, 466.16, 523.25] // Minor Pentatonic C4..C5
        let f = freqs[localIdx % freqs.count] * keyRatio

        for i in 0..<n {
            let t = Double(i) / sr
            let attack = min(1.0, t / 0.008)
            let decay = exp(-t * ((genre == .lofi || genre == .rnb) ? 3.2 : 5.2))
            let env = attack * decay

            let sig: Double
            switch genre {
            case .phonk: // Classic Memphis Cowbell
                let o1 = (sin(2.0 * .pi * f * 1.48 * t) > 0 ? 1.0 : -1.0)
                let o2 = (sin(2.0 * .pi * f * 2.15 * t) > 0 ? 1.0 : -1.0)
                sig = (o1 * 0.55 + o2 * 0.45) * 0.52 * exp(-t * 7.5)
            case .lofi, .rnb, .hipHop: // Warm Rhodes Chord
                let root = sin(2.0 * .pi * f * t)
                let third = sin(2.0 * .pi * (f * 1.1892) * t) * 0.55
                let fifth = sin(2.0 * .pi * (f * 1.4983) * t) * 0.45
                let seventh = sin(2.0 * .pi * (f * 1.7818) * t) * 0.35
                sig = (root + third + fifth + seventh) * 0.38
            case .synthwave: // 80s Analog Brass
                let s1 = ((f * t).truncatingRemainder(dividingBy: 1.0)) * 2.0 - 1.0
                let s2 = (((f * 1.007) * t).truncatingRemainder(dividingBy: 1.0)) * 2.0 - 1.0
                sig = (s1 + s2) * 0.38
            default: // Supersaw / Pluck
                let s1 = ((f * t).truncatingRemainder(dividingBy: 1.0)) * 2.0 - 1.0
                let s2 = (((f * 0.994) * t).truncatingRemainder(dividingBy: 1.0)) * 2.0 - 1.0
                let s3 = (((f * 1.006) * t).truncatingRemainder(dividingBy: 1.0)) * 2.0 - 1.0
                sig = (s1 + s2 + s3) * 0.28
            }
            out[i] = Float(max(-1.0, min(1.0, sig * env * 0.85)))
        }
        return out
    }

    private static func synthFx(localIdx: Int, genre: MusicGenre, sr: Double) -> [Float] {
        let dur = 0.68
        let n = Int(sr * dur)
        var out = [Float](repeating: 0, count: n)
        var seed: UInt64 = UInt64(localIdx * 7919 + genre.rawValue.count)
        for i in 0..<n {
            let t = Double(i) / sr
            seed = (seed &* 6364136223846793005) &+ 1
            let noise = (Double(Int64(bitPattern: seed >> 1) & 0x7FFF_FFFF) / Double(0x7FFF_FFFF)) * 2.0 - 1.0
            let sig: Double
            switch localIdx {
            case 0: // Riser Sweep
                let freq = 220.0 + 1800.0 * (t / dur)
                sig = (sin(2.0 * .pi * freq * t) * 0.45 + noise * 0.25) * min(1.0, t / 0.15) * (1.0 - t / dur)
            case 1: // Laser Zapp
                let freq = 1400.0 * exp(-t * 12.0) + 90.0
                sig = sin(2.0 * .pi * freq * t) * exp(-t * 5.0)
            case 2: // Crash
                sig = noise * exp(-t * 3.8) * 0.65
            case 3: // Tom / Sub Drop
                let freq = 150.0 * exp(-t * 6.0) + 45.0
                sig = sin(2.0 * .pi * freq * t) * exp(-t * 4.5)
            case 4: // Vocal Chant "Hey" formant
                let f0 = 210.0 * (1.0 - 0.15 * t)
                let formant = sin(2.0 * .pi * 680.0 * t) * sin(2.0 * .pi * f0 * t)
                sig = (formant * 0.65 + noise * 0.12) * exp(-t * 5.5)
            default: // Vocal Chop "Oh"
                let f0 = 290.0
                let formant = sin(2.0 * .pi * 490.0 * t) * (sin(2.0 * .pi * f0 * t) > 0 ? 0.7 : -0.7)
                sig = formant * exp(-t * 4.5) * 0.65
            }
            out[i] = Float(max(-1.0, min(1.0, sig * 0.8)))
        }
        return out
    }
}
