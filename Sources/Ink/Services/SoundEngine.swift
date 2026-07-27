import AVFoundation
import UniformTypeIdentifiers

final class SoundEngine {
    enum CharacterType: String, CaseIterable {
        case char, space, enter, delete
    }

    var volume: Double = 0.5 {
        didSet { player.volume = Float(volume) }
    }

    var baseFrequency: Double = 4200
    var baseDuration: Double = 0.006
    var baseNoise: Double = 0.3

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var buffers: [CharacterType: [AVAudioPCMBuffer]] = [:]
    private var lastIndex: [CharacterType: Int] = [:]
    private let sampleRate: Double = 44100

    init() {
        let mixer = engine.mainMixerNode
        engine.attach(player)
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        engine.connect(player, to: mixer, format: fmt)
        generateAllSounds()
        do {
            if !engine.isRunning { try engine.start() }
        } catch {
            print("SoundEngine: failed to start — \(error.localizedDescription)")
        }
    }

    func regenerate() {
        generateAllSounds()
    }

    private func generateAllSounds() {
        func make(_ count: Int, gen: (Int) -> AVAudioPCMBuffer) -> [AVAudioPCMBuffer] {
            (0..<count).map(gen)
        }
        buffers[.char]   = make(8)  { generateClick(seed: $0, freq: baseFrequency, dur: baseDuration, vol: 0.5) }
        buffers[.space]  = make(4)  { generateClick(seed: $0, freq: baseFrequency * 0.83, dur: baseDuration * 0.7, vol: 0.35) }
        buffers[.enter]  = make(3)  { generateClick(seed: $0, freq: baseFrequency * 0.67, dur: baseDuration * 2.0, vol: 0.45) }
        buffers[.delete] = make(3)  { generateClick(seed: $0, freq: baseFrequency * 1.19, dur: baseDuration * 0.5, vol: 0.4) }
    }

    private func generateClick(seed: Int, freq: Double, dur: Double, vol: Double) -> AVAudioPCMBuffer {
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let count = Int(dur * sampleRate)
        let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(max(count, 1)))!
        buf.frameLength = AVAudioFrameCount(max(count, 1))

        var rng = SeededRNG(seed: seed)
        let data = buf.floatChannelData![0]
        let f = freq + Double(seed % 5 - 2) * 300
        let a = vol * (0.9 + Double(seed % 3) * 0.05)

        for i in 0..<max(count, 1) {
            let t = Double(i) / sampleRate
            let env = exp(-t * (1.0 / dur) * 8)
            let noise = Float.random(in: -1...1, using: &rng) * Float(baseNoise)
            let tone = sin(Float(t * f * 2 * .pi)) * 0.7
            data[i] = (tone + noise) * Float(env) * Float(a)
        }
        return buf
    }

    func setCustomSound(_ type: CharacterType, url: URL) {
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        guard let file = try? AVAudioFile(forReading: url),
              let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(file.length))
        else { return }
        buf.frameLength = AVAudioFrameCount(file.length)
        do {
            try file.read(into: buf)
            buffers[type] = [buf]
        } catch {
            print("SoundEngine: failed to read \(url.lastPathComponent) — \(error.localizedDescription)")
        }
    }

    func resetCustomSound(_ type: CharacterType) {
        regenerate()
    }

    func play(_ type: CharacterType) {
        guard let typeBuffers = buffers[type], !typeBuffers.isEmpty else { return }

        var index: Int
        repeat {
            index = Int.random(in: 0..<typeBuffers.count)
        } while index == lastIndex[type] && typeBuffers.count > 1
        lastIndex[type] = index

        player.volume = Float(volume) * Float.random(in: 0.9...1.1)
        player.scheduleBuffer(typeBuffers[index], at: nil, options: .interruptsAtLoop)
        if !engine.isRunning { try? engine.start() }
        player.play()
    }

    func playAll() {
        for type in CharacterType.allCases {
            play(type)
            Thread.sleep(forTimeInterval: 0.15)
        }
    }
}

private struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: Int) {
        state = UInt64(seed)
        if state == 0 { state = 1 }
    }
    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
