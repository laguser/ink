<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="github/icon.png">
    <img src="github/icon.png" width="96" alt="Ink">
  </picture>
</p>

<h1 align="center">Ink</h1>

<p align="center">
  <b>Minimalist Markdown Editor for macOS</b><br>
  <sub>No chrome. No clutter. Just you and your words.</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey?style=flat-square">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
  <img src="https://img.shields.io/badge/release-v1.0.0-black?style=flat-square">
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#download">Download</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#plugin-api">Plugins</a> •
  <a href="#building-from-source">Build</a>
</p>

---

## Download

[**Download Ink.dmg**](https://github.com/laguser/ink/releases/latest/download/Ink.dmg) — macOS 14+, Intel & Apple Silicon

Or build from source (see below).

---

## Features

| | |
|---|---|
| ✍️ **Distraction-free** | Hidden title bar, full-width editor, no tabs |
| 🎹 **Keyboard sounds** | Synthetic clicks (like iOS keyboard) — adjustable pitch, duration, noise |
| 👁️ **Live Preview** | WKWebView renders headings, lists, code, tables, quotes |
| 📁 **Workspaces** | Plain folders of `.md` files — switch, create, open in Finder |
| 🧩 **Plugin system** | Auto Complete, Word Highlighter, Focus Mode, Particles & more |
| 🌍 **i18n** | English, Русский, 日本語 — switch in Settings |
| ⌨️ **Custom shortcuts** | Remap every action in Settings → Shortcuts |
| 🎨 **Animations** | Slide / Fade / Scale transitions between documents |
| 📦 **Export** | TXT, PDF, Markdown — single or batch |

---

## Screenshots

*Coming soon.*

---

## Quick Start

```bash
git clone https://github.com/laguser/ink.git
cd ink
swift run
```

On first launch, Ink will ask you to create or choose a workspace folder.  
Documents are saved as `{Title}.md` in that folder.

---

## Keyboard Shortcuts

| Shortcut | Action | Customisable |
|---|---|---|
| `⌘N` | New Document | ✅ |
| `⌘S` | Save | ✅ |
| `⌘,` | Settings | ✅ |
| `⌘⇧P` | Toggle Preview | ✅ |
| `⌘⇧S` | Toggle Sidebar | ✅ |

All shortcuts are remappable in **Settings → Shortcuts**.

---

## Plugin API

Plugins live in `{workspace}/plugins/{id}/plugin.json`.

| Plugin | Description |
|---|---|
| **Auto Complete** | Suggests word completions as you type (Tab/Enter to navigate) |
| **Word Highlighter** | Highlights all occurrences of a selected word |
| **Auto Capitalize** | Capitalizes first letter after `.`, `!`, `?` |
| **Focus Mode** | Highlights current line, dims the rest |
| **Particles** | Colored particle burst on each keystroke |

Full API reference → [`github/PLUGIN_API.md`](github/PLUGIN_API.md)

---

## Workspaces

Workspaces are plain directories of Markdown files. You can:

- **Create** one on first launch
- **Add** an existing folder of `.md` files
- **Switch** between workspaces from the sidebar footer
- **Open in Finder** directly from the workspace menu
- **Remove** a workspace from the list

---

## Settings

| Section | Options |
|---|---|
| General | Font, size, line height, auto-save, spell check |
| Sound | Volume, engine, frequency, duration, noise, custom samples |
| Typography | Typeface, size, line spacing |
| Animation | Style (slide/fade/scale/none), duration |
| Shortcuts | Remap any keyboard shortcut with recording UI |
| Plugins | Enable/disable, configure per-plugin settings |
| Language | English / Русский / 日本語 |
| Export | TXT, PDF, Markdown — single or all documents |

---

## Building from Source

```bash
# Debug
swift build

# Release
swift build -c release

# Run directly
swift run

# Or use the build script
./build_and_run.sh
```

- **macOS 14+** required
- **No external dependencies** — pure SwiftUI + AppKit

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI + AppKit hybrid |
| Editor | `NSTextView` subclass with typewriter animations |
| Preview | `WKWebView` + custom Markdown→HTML converter |
| Storage | JSON (`Application Support/Ink/`) + plain `.md` files |
| Sounds | Programmatic sine-wave synthesis (CoreAudio) |
| Plugins | JSON-based local plugin system with ColorPicker, Actions, Settings |

---

## License

MIT © Nicolay

---

<p align="center">
  <sub>Built with ❤️ for people who love to write.</sub>
</p>
