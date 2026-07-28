import Foundation

@Observable
final class AppSettings {
    var fontSize: Double        { didSet { sync() } }
    var fontName: String        { didSet { sync() } }
    var soundVolume: Double     { didSet { sync() } }
    var isSoundEnabled: Bool    { didSet { sync() } }
    var isAutoSaveEnabled: Bool { didSet { sync() } }
    var isSpellCheckEnabled: Bool { didSet { sync() } }
    var hideMenuBarInFullscreen: Bool { didSet { sync() } }
    var lineHeight: Double      { didSet { sync() } }
    var soundEngine: String     { didSet { sync() } }
    var clickFrequency: Double  { didSet { sync() } }
    var clickDuration: Double   { didSet { sync() } }
    var clickNoise: Double      { didSet { sync() } }

    // Animation
    var animationStyle: String { didSet { sync() } }
    var animationDuration: Double { didSet { sync() } }

    // Donation
    var donationLink: String { didSet { sync() } } // freeform URL or payment identifier


    static let shared = AppSettings()

    private init() {
        let d = UserDefaults.standard
        fontSize = d.object(forKey: "fontSize") as? Double ?? 22
        fontName = d.string(forKey: "fontName") ?? "SF Mono"
        soundVolume = d.object(forKey: "soundVolume") as? Double ?? 0.7
        isSoundEnabled = d.object(forKey: "isSoundEnabled") as? Bool ?? true
        isAutoSaveEnabled = d.object(forKey: "isAutoSaveEnabled") as? Bool ?? true
        isSpellCheckEnabled = d.object(forKey: "isSpellCheckEnabled") as? Bool ?? false
        hideMenuBarInFullscreen = d.object(forKey: "hideMenuBarInFullscreen") as? Bool ?? true
        lineHeight = d.object(forKey: "lineHeight") as? Double ?? 1.5
        soundEngine = d.string(forKey: "soundEngine") ?? "synth"
        clickFrequency = d.object(forKey: "clickFrequency") as? Double ?? 4200
        clickDuration = d.object(forKey: "clickDuration") as? Double ?? 0.006
        clickNoise = d.object(forKey: "clickNoise") as? Double ?? 0.3
        animationStyle = d.string(forKey: "animationStyle") ?? "slide"
        animationDuration = d.object(forKey: "animationDuration") as? Double ?? 0.35
        donationLink = d.string(forKey: "donationLink") ?? ""
    }

    private func sync() {
        let d = UserDefaults.standard
        d.set(fontSize, forKey: "fontSize")
        d.set(fontName, forKey: "fontName")
        d.set(soundVolume, forKey: "soundVolume")
        d.set(isSoundEnabled, forKey: "isSoundEnabled")
        d.set(isAutoSaveEnabled, forKey: "isAutoSaveEnabled")
        d.set(isSpellCheckEnabled, forKey: "isSpellCheckEnabled")
        d.set(hideMenuBarInFullscreen, forKey: "hideMenuBarInFullscreen")
        d.set(lineHeight, forKey: "lineHeight")
        d.set(soundEngine, forKey: "soundEngine")
        d.set(clickFrequency, forKey: "clickFrequency")
        d.set(clickDuration, forKey: "clickDuration")
        d.set(clickNoise, forKey: "clickNoise")
        d.set(animationStyle, forKey: "animationStyle")
        d.set(animationDuration, forKey: "animationDuration")
    }
}
