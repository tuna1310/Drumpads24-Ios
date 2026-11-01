import Foundation

public protocol PadRepositoryProtocol: Sendable {
    func getPads() -> [Pad]
    func getPad(at index: Int) -> Pad?
}

public final class DefaultPadRepository: PadRepositoryProtocol, @unchecked Sendable {
    public static let shared = DefaultPadRepository()

    public let pads: [Pad] = [
        // DRUMS (0..5) - Red group
        Pad(index: 0, name: "Kick Punch", group: .drum, sampleId: "drum_kick_punch", sampleFile: "starter/samples/kick_punch.wav", colorHex: "#E53935"),
        Pad(index: 1, name: "Kick Deep", group: .drum, sampleId: "drum_kick_deep", sampleFile: "starter/samples/kick_deep.wav", colorHex: "#E53935"),
        Pad(index: 2, name: "Snare Ac", group: .drum, sampleId: "drum_snare_acoustic", sampleFile: "starter/samples/snare_acoustic.wav", colorHex: "#E53935"),
        Pad(index: 3, name: "Snare El", group: .drum, sampleId: "drum_snare_electro", sampleFile: "starter/samples/snare_electro.wav", colorHex: "#E53935"),
        Pad(index: 4, name: "Hat Cl", group: .drum, sampleId: "drum_hat_closed", sampleFile: "starter/samples/hat_closed.wav", colorHex: "#E53935"),
        Pad(index: 5, name: "Hat Op", group: .drum, sampleId: "drum_hat_open", sampleFile: "starter/samples/hat_open.wav", colorHex: "#E53935"),

        // BASS (6..11) - Purple group
        Pad(index: 6, name: "Sub C", group: .bass, sampleId: "bass_sub_c", sampleFile: "starter/samples/bass_sub_c.wav", colorHex: "#8E24AA"),
        Pad(index: 7, name: "Sub D", group: .bass, sampleId: "bass_sub_d", sampleFile: "starter/samples/bass_sub_d.wav", colorHex: "#8E24AA"),
        Pad(index: 8, name: "Pluck E", group: .bass, sampleId: "bass_pluck_e", sampleFile: "starter/samples/bass_pluck_e.wav", colorHex: "#8E24AA"),
        Pad(index: 9, name: "Pluck G", group: .bass, sampleId: "bass_pluck_g", sampleFile: "starter/samples/bass_pluck_g.wav", colorHex: "#8E24AA"),
        Pad(index: 10, name: "Synth A", group: .bass, sampleId: "bass_synth_a", sampleFile: "starter/samples/bass_synth_a.wav", colorHex: "#8E24AA"),
        Pad(index: 11, name: "Synth C", group: .bass, sampleId: "bass_synth_c", sampleFile: "starter/samples/bass_synth_c.wav", colorHex: "#8E24AA"),

        // MELODY (12..17) - Teal group
        Pad(index: 12, name: "Lead C4", group: .melody, sampleId: "melody_lead_c4", sampleFile: "starter/samples/melody_lead_c4.wav", colorHex: "#00897B"),
        Pad(index: 13, name: "Lead D4", group: .melody, sampleId: "melody_lead_d4", sampleFile: "starter/samples/melody_lead_d4.wav", colorHex: "#00897B"),
        Pad(index: 14, name: "Lead E4", group: .melody, sampleId: "melody_lead_e4", sampleFile: "starter/samples/melody_lead_e4.wav", colorHex: "#00897B"),
        Pad(index: 15, name: "Lead G4", group: .melody, sampleId: "melody_lead_g4", sampleFile: "starter/samples/melody_lead_g4.wav", colorHex: "#00897B"),
        Pad(index: 16, name: "Lead A4", group: .melody, sampleId: "melody_lead_a4", sampleFile: "starter/samples/melody_lead_a4.wav", colorHex: "#00897B"),
        Pad(index: 17, name: "Pluck C5", group: .melody, sampleId: "melody_pluck_c5", sampleFile: "starter/samples/melody_pluck_c5.wav", colorHex: "#00897B"),

        // FX (18..23) - Orange group
        Pad(index: 18, name: "Tom Low", group: .fx, sampleId: "fx_tom_low", sampleFile: "starter/samples/tom_low.wav", colorHex: "#FB8C00"),
        Pad(index: 19, name: "Tom High", group: .fx, sampleId: "fx_tom_high", sampleFile: "starter/samples/tom_high.wav", colorHex: "#FB8C00"),
        Pad(index: 20, name: "Crash", group: .fx, sampleId: "fx_crash", sampleFile: "starter/samples/fx_crash.wav", colorHex: "#FB8C00"),
        Pad(index: 21, name: "Laser", group: .fx, sampleId: "fx_laser", sampleFile: "starter/samples/fx_laser.wav", colorHex: "#FB8C00"),
        Pad(index: 22, name: "Chant Hey", group: .fx, sampleId: "fx_chant_hey", sampleFile: "starter/samples/vocal_chant_hey.wav", colorHex: "#FB8C00"),
        Pad(index: 23, name: "Chop Oh", group: .fx, sampleId: "fx_chop_oh", sampleFile: "starter/samples/vocal_chop_oh.wav", colorHex: "#FB8C00")
    ]

    public init() {}

    public func getPads() -> [Pad] { pads }

    public func getPad(at index: Int) -> Pad? {
        guard index >= 0 && index < pads.count else { return nil }
        return pads[index]
    }
}
