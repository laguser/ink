import Foundation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case russian = "ru"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english:  "English"
        case .russian:  "Русский"
        case .japanese: "日本語"
        }
    }
}

@Observable
final class LocalizationManager {
    var language: AppLanguage {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
        }
    }

    static let shared = LocalizationManager()

    private let strings: [AppLanguage: [String: String]] = [
        .english: [:],

        .russian: [
            "words": "слов",
            "chars": "симв",
            "read": "чтения",

            "General": "Общие",
            "Typography": "Типография",
            "Sound": "Звук",
            "Export": "Экспорт",
            "Animation": "Анимация",
            "Cursor": "Курсор",
            "About": "О программе",
            "Shortcuts": "Горячие клавиши",
            "Plugins": "Плагины",
            "Language": "Язык",

            "Source": "Исходник",
            "Preview": "Превью",
            "Settings": "Настройки",
            "Back": "Назад",
            "Close": "Закрыть",
            "Close Settings": "Закрыть настройки",

            "New Document": "Новый документ",
            "Delete": "Удалить",
            "Rename": "Переименовать",
            "Duplicate": "Дублировать",

            "Workspaces": "Рабочие пространства",
            "New Workspace...": "Новое пространство…",
            "Open Folder...": "Открыть папку…",
            "Open in Finder": "Показать в Finder",
            "Remove Workspace": "Удалить пространство",
            "No Workspace": "Нет пространства",

            "Key Bindings": "Привязки клавиш",
            "Press shortcut...": "Нажмите комбинацию…",
            "Reset": "Сбросить",
            "Reset All": "Сбросить всё",

            "Installed": "Установлены",
            "Cloud Plugins": "Облачные плагины",
            "Coming Soon": "Скоро",
            "Reload Plugins": "Перезагрузить плагины",
            "Actions": "Действия",
            "Version": "Версия",

            "Auto Save": "Автосохранение",
            "Font": "Шрифт",
            "Font Size": "Размер шрифта",
            "Line Height": "Межстрочный интервал",
            "Spell Check": "Проверка орфографии",

            "Volume": "Громкость",
            "Pitch": "Высота тона",
            "Custom Sound": "Пользовательский звук",
            "Character": "Символ",
            "Space": "Пробел",
            "Enter": "Ввод",

            "Transition Style": "Стиль перехода",
            "None": "Нет",
            "Slide": "Сдвиг",
            "Fade": "Исчезание",
            "Scale": "Масштаб",

            "Cursor Style": "Стиль курсора",
            "Block": "Блок",
            "Line": "Линия",
            "Underline": "Подчёркивание",
            "Custom 8×16": "Свой 8×16",
            "Cursor Width": "Ширина курсора",
            "Cursor Color": "Цвет курсора",
            "Pixel Editor": "Пиксельный редактор",

            "Export as TXT": "Экспорт TXT",
            "Export as PDF": "Экспорт PDF",
            "Export as Markdown": "Экспорт Markdown",
            "Export All": "Экспорт всего",

            "About Ink": "О Ink",
            "Made with SwiftUI": "Сделано на SwiftUI",
        ],

        .japanese: [
            "words": "単語",
            "chars": "文字",
            "read": "読了",

            "General": "一般",
            "Typography": "タイポグラフィ",
            "Sound": "サウンド",
            "Export": "エクスポート",
            "Animation": "アニメーション",
            "Cursor": "カーソル",
            "About": "情報",
            "Shortcuts": "ショートカット",
            "Plugins": "プラグイン",
            "Language": "言語",

            "Source": "ソース",
            "Preview": "プレビュー",
            "Settings": "設定",
            "Back": "戻る",
            "Close": "閉じる",
            "Close Settings": "設定を閉じる",

            "New Document": "新規文書",
            "Delete": "削除",
            "Rename": "名称変更",
            "Duplicate": "複製",

            "Workspaces": "ワークスペース",
            "New Workspace...": "新規ワークスペース…",
            "Open Folder...": "フォルダを開く…",
            "Open in Finder": "Finderで開く",
            "Remove Workspace": "ワークスペースを削除",
            "No Workspace": "ワークスペースなし",

            "Key Bindings": "キー割り当て",
            "Press shortcut...": "ショートカットを押す…",
            "Reset": "リセット",
            "Reset All": "すべてリセット",

            "Installed": "インストール済み",
            "Cloud Plugins": "クラウドプラグイン",
            "Coming Soon": "近日公開",
            "Reload Plugins": "プラグインを再読み込み",
            "Actions": "アクション",
            "Version": "バージョン",

            "Auto Save": "自動保存",
            "Font": "フォント",
            "Font Size": "フォントサイズ",
            "Line Height": "行間",
            "Spell Check": "スペルチェック",

            "Volume": "音量",
            "Pitch": "ピッチ",
            "Custom Sound": "カスタムサウンド",
            "Character": "文字",
            "Space": "スペース",
            "Enter": "エンター",

            "Transition Style": "トランジション",
            "None": "なし",
            "Slide": "スライド",
            "Fade": "フェード",
            "Scale": "スケール",

            "Cursor Style": "カーソルスタイル",
            "Block": "ブロック",
            "Line": "ライン",
            "Underline": "下線",
            "Custom 8×16": "カスタム 8×16",
            "Cursor Width": "カーソル幅",
            "Cursor Color": "カーソル色",
            "Pixel Editor": "ピクセルエディタ",

            "Export as TXT": "TXTエクスポート",
            "Export as PDF": "PDFエクスポート",
            "Export as Markdown": "Markdownエクスポート",
            "Export All": "すべてエクスポート",

            "About Ink": "Inkについて",
            "Made with SwiftUI": "SwiftUIで制作",
        ]
    ]

    private init() {
        let raw = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        language = AppLanguage(rawValue: raw) ?? .english
    }

    func localized(_ key: String) -> String {
        if language == .english { return key }
        return strings[language]?[key] ?? key
    }
}

func tr(_ key: String) -> String {
    LocalizationManager.shared.localized(key)
}
