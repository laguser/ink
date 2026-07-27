import Foundation

@MainActor
@Observable
final class EditorViewModel {
    var text: String = ""
    var cursorPosition: Int = 0

    var fontSize: Double { settings.fontSize }
    var fontName: String { settings.fontName }
    var isSoundEnabled: Bool { settings.isSoundEnabled }
    var soundVolume: Double { settings.soundVolume }
    var lineHeight: Double { settings.lineHeight }
    var settings: AppSettings { _settings }
    var windowWidth: CGFloat = 900
    var store: DocumentStore

    var suggestions: [String] = []
    var selectedSuggestion: Int = 0
    var showSuggestions: Bool = false

    var wordCount: Int {
        text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
    var charCount: Int { text.count }
    var readingTime: String {
        let w = max(1, wordCount)
        let totalSec = w * 60 / 200
        let min = totalSec / 60
        let sec = totalSec % 60
        if min > 0 { return "\(min)m \(sec)s \(tr("read"))" }
        return "\(max(1, sec))s \(tr("read"))"
    }

    var actualFontSize: Double {
        max(12, min(36, fontSize * (windowWidth / 900)))
    }

    private let _settings: AppSettings
    let soundEngine = SoundEngine()
    private var autoSaveTask: Task<Void, Never>?

    init() {
        _settings = AppSettings.shared
        soundEngine.volume = _settings.soundVolume
        soundEngine.baseFrequency = _settings.clickFrequency
        soundEngine.baseDuration = _settings.clickDuration
        soundEngine.baseNoise = _settings.clickNoise
        store = DocumentStore()
        if WorkspaceManager.shared.activeWorkspace != nil {
            store.writeDocumentFiles()
        }
        loadActive()
    }

    func loadActive() {
        guard let doc = store.activeDocument else { return }
        text = doc.text
        cursorPosition = doc.cursorPosition
    }

    // MARK: – Document management

    func selectDocument(_ id: UUID) {
        saveToStore()
        store.activeDocumentId = id
        loadActive()
        store.save()
    }

    func createDocument() {
        saveToStore()
        let doc = store.createDocument()
        _ = doc
        loadActive()
    }

    func deleteDocument(_ id: UUID) {
        store.deleteDocument(id)
        loadActive()
    }

    private func saveToStore() {
        guard let doc = store.activeDocument else { return }
        doc.text = text
        doc.cursorPosition = cursorPosition
    }

    // MARK: – Input handling

    func onCharacterTyped(_ character: String) {
        switch character {
        case "\n": if isSoundEnabled { soundEngine.play(.enter) }
        case " ":  if isSoundEnabled { soundEngine.play(.space) }
        default:   if isSoundEnabled { soundEngine.play(.char) }
        }
        scheduleAutoSave()
    }

    func selectNextSuggestion() {
        guard showSuggestions, !suggestions.isEmpty else { return }
        selectedSuggestion = (selectedSuggestion + 1) % suggestions.count
    }

    func selectPrevSuggestion() {
        guard showSuggestions, !suggestions.isEmpty else { return }
        selectedSuggestion = (selectedSuggestion - 1 + suggestions.count) % suggestions.count
    }

    func applySelectedSuggestion() -> Bool {
        guard showSuggestions, selectedSuggestion >= 0, selectedSuggestion < suggestions.count else { return false }
        applySuggestion(suggestions[selectedSuggestion])
        return true
    }

    func applySuggestion(_ sug: String) {
        let pos = cursorPosition
        let prefix = currentWordPrefix()
        guard !prefix.isEmpty, pos >= prefix.count else { return }
        let start = text.index(text.startIndex, offsetBy: pos - prefix.count)
        let end = text.index(text.startIndex, offsetBy: pos)
        var newText = text
        newText.replaceSubrange(start..<end, with: sug)
        onTextChanged(newText, cursor: pos - prefix.count + sug.count)
        showSuggestions = false
    }

    func dismissSuggestions() {
        showSuggestions = false
    }

    private func currentWordPrefix() -> String {
        let pos = cursorPosition
        guard pos > 0, pos <= text.count else { return "" }
        let idx = text.index(text.startIndex, offsetBy: pos)
        let before = String(text[text.startIndex..<idx])
        let words = before.components(separatedBy: CharacterSet.whitespacesAndNewlines)
        guard let last = words.last, !last.isEmpty else { return "" }
        return last
    }

    func updateSuggestions(cursorRect: CGRect) {
        let prefix = currentWordPrefix()
        let results = PluginManager.shared.autocompleteSuggestions(for: prefix, in: text)
        if results.isEmpty {
            showSuggestions = false
            return
        }
        suggestions = results
        selectedSuggestion = 0
        suggestionCursorRect = cursorRect
        showSuggestions = true
    }

    var suggestionCursorRect: CGRect = .zero

    func onDelete() {
        if isSoundEnabled { soundEngine.play(.delete) }
        scheduleAutoSave()
    }

    func onTextChanged(_ newText: String, cursor: Int) {
        text = newText
        cursorPosition = cursor
        if let id = store.activeDocumentId {
            store.updateDocumentText(id, text: newText)
            store.updateCursorPosition(id, cursor: cursor)
        }
    }

    // MARK: – Auto‑save

    private func scheduleAutoSave() {
        guard _settings.isAutoSaveEnabled else { return }
        autoSaveTask?.cancel()
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            self?.performSave()
        }
    }

    func saveImmediately() {
        autoSaveTask?.cancel()
        performSave()
    }

    private func performSave() {
        guard let id = store.activeDocumentId else { return }
        store.updateDocumentText(id, text: text)
        store.updateCursorPosition(id, cursor: cursorPosition)
        store.save()
        store.writeDocumentFiles()
    }

    // MARK: – Settings

    func updateVolume(_ v: Double) {
        _settings.soundVolume = v
        soundEngine.volume = v
    }

    func updateSynthParams() {
        soundEngine.baseFrequency = _settings.clickFrequency
        soundEngine.baseDuration = _settings.clickDuration
        soundEngine.baseNoise = _settings.clickNoise
        soundEngine.regenerate()
    }

    func testSound() {
        if isSoundEnabled { soundEngine.play(.char) }
    }

    func testAllSounds() {
        soundEngine.playAll()
    }

    func setCustomSound(_ type: SoundEngine.CharacterType, url: URL) {
        soundEngine.setCustomSound(type, url: url)
    }

    func resetCustomSound(_ type: SoundEngine.CharacterType) {
        soundEngine.resetCustomSound(type)
    }

    // MARK: – Export

    func exportTXT() { ExportService.export(text: text, format: .txt) }
    func exportPDF() { ExportService.export(text: text, format: .pdf) }
    func exportMarkdown() { ExportService.export(text: text, format: .markdown) }
    func exportAll() { store.exportAll() }
}
