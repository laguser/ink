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
  <a href="https://github.com/laguser/ink/releases/latest">
    <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey?style=flat-square">
  </a>
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square">
  <img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square">
  <a href="https://github.com/laguser/ink/releases/latest">
    <img src="https://img.shields.io/badge/release-v1.0.0-black?style=flat-square">
  </a>
  <img src="https://img.shields.io/badge/download-2.2K-brightgreen?style=flat-square">
</p>

<p align="center">
  <a href="https://github.com/laguser/ink/releases/latest">
    <b>Download Ink.dmg</b> (macOS 14+, Apple Silicon & Intel)
  </a>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#download">Download</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#keyboard-shortcuts">Shortcuts</a> •
  <a href="#plugins">Plugins</a> •
  <a href="#building">Build</a>
</p>

---

<h2 id="features">Features</h2>

<table>
<tr><td width="60">✍️</td><td><b>Distraction‑free</b><br>Hidden title bar, full‑width editor, no tabs — pure focus</td></tr>
<tr><td>🎹</td><td><b>Keyboard sounds</b><br>Synthetic click engine (like iOS keyboard) — adjustable pitch, duration, noise</td></tr>
<tr><td>👁️</td><td><b>Live Preview</b><br>WKWebView renders headings, lists, code blocks, tables, quotes, images, links</td></tr>
<tr><td>📁</td><td><b>Workspaces</b><br>Plain folders of `.md` files — switch, create, open in Finder</td></tr>
<tr><td>🧩</td><td><b>Cloud Plugins</b><br>21 plugins available via community repository — install with one click</td></tr>
<tr><td>🌍</td><td><b>i18n</b><br>English, Русский, 日本語 — switch in Settings</td></tr>
<tr><td>⌨️</td><td><b>Custom shortcuts</b><br>Remap every action in Settings → Shortcuts with recording UI</td></tr>
<tr><td>🎨</td><td><b>Animations</b><br>Slide / Fade / Scale transitions between documents</td></tr>
<tr><td>📦</td><td><b>Export</b><br>TXT, PDF, Markdown — single document or batch export all</td></tr>
</table>

---

<h2 id="download">Download</h2>

<p align="center">
  <a href="https://github.com/laguser/ink/releases/latest/download/Ink.dmg">
    <img src="https://img.shields.io/badge/⬇%20Download%20Ink.dmg-1d1d1f?style=for-the-badge" alt="Download">
  </a>
</p>

Or build from source (see below).

---

<h2 id="quick-start">Quick Start</h2>

```bash
git clone https://github.com/laguser/ink.git
cd ink
swift run
```

On first launch, Ink asks you to create or choose a workspace folder.  
Documents are saved automatically as `{Title}.md` files.

---

<h2 id="keyboard-shortcuts">Keyboard Shortcuts</h2>

| Shortcut | Action | Customisable |
|---|---|---|
| `⌘N` | New Document | ✅ |
| `⌘S` | Save | ✅ |
| `⌘,` | Settings | ✅ |
| `⌘⇧P` | Toggle Preview | ✅ |
| `⌘⇧S` | Toggle Sidebar | ✅ |

All shortcuts are remappable in **Settings → Shortcuts** with a live recording UI.

---

<h2 id="plugins">Plugins</h2>

Ink has a two‑tier plugin system:

### Built‑in Behaviour

These plugin behaviours are compiled into the app. Install their metadata from the cloud to configure them:

| Plugin | Description |
|---|---|
| **Auto Complete** | Suggests word completions as you type (Tab/Enter/Escape) |
| **Word Highlighter** | Highlights all occurrences of a selected word |
| **Auto Capitalize** | Capitalizes sentences + 500+ proper nouns (names, countries, cities, rivers, lakes, oceans) |
| **Focus Mode** | Highlights current line, dims the rest |
| **Particles** | Colored particle burst on each keystroke |

### Cloud‑Only (install from Settings → Plugins → Browse Cloud)

| Plugin | Description |
|---|---|
| **Typewriter Sounds** | Preset sound profiles: mechanical, typewriter, retro, soft |
| **Text Stats** | Live word count, chars, paragraphs, readability, WPM |
| **Daily Goal** | Track daily word count progress with visual bar |
| **Reading Time** | Estimated reading and speaking time |
| **Smooth Scroll** | Animated scrolling with adjustable speed |
| **Typewriter Scroll** | Keep current line vertically centred |
| **Char Echo** | Animated trail on each keystroke |
| **Word Rain** | Animated word rain background effect |
| **Session Timer** | Pomodoro‑style writing timer |
| **Auto Backup** | Automatic versioned backups |
| **Font Randomizer** | Random monospace font on new document |
| **Writing Prompts** | Random prompts to fight writer's block |
| **Focus Music** | Ambient soundscapes: lofi, rain, cafe, ocean |
| **Zen Mode** | Combines Focus + Sounds + Smooth Scroll |
| **Smart Quotes** | Straight → curly quotes, em dashes |
| **Inline Code** | Auto‑style backtick‑wrapped text |

Plugins are stored per‑workspace in `{workspace}/plugins/{id}/plugin.json`.  
Full API reference → [`github/PLUGIN_API.md`](github/PLUGIN_API.md)

---

<h2 id="workspaces">Workspaces</h2>

Workspaces are plain directories of Markdown files. You can:

- **Create** one on first launch
- **Add** an existing folder of `.md` files
- **Switch** between workspaces from the sidebar footer
- **Open in Finder** directly from the workspace menu
- **Remove** a workspace from the list

---

<h2 id="settings">Settings</h2>

| Section | Options |
|---|---|
| General | Font, size, line height, auto‑save, spell check |
| Sound | Volume, engine (synth / samples), frequency, duration, noise, custom samples |
| Typography | Typeface, size, line spacing |
| Animation | Style (slide / fade / scale / none), duration |
| Shortcuts | Remap every keyboard shortcut with recording UI |
| Plugins | Enable / disable, configure per‑plugin settings, browse cloud plugins |
| Language | English / Русский / 日本語 |
| Export | TXT, PDF, Markdown — single or all documents |

---

<h2 id="building">Building from Source</h2>

**Requires macOS 14+ and Xcode 15+.**

```bash
# Debug
swift build

# Release
swift build -c release

# Run
swift run

# Or use the build script
./build_and_run.sh
```

No external dependencies — pure SwiftUI + AppKit.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI + AppKit hybrid |
| Editor | `NSTextView` subclass with typewriter animations |
| Preview | `WKWebView` + custom Markdown→HTML converter |
| Storage | JSON (`Application Support/Ink/`) + plain `.md` files |
| Sounds | Programmatic sine‑wave synthesis (CoreAudio) |
| Plugins | JSON‑based local + cloud plugin system |

---

## License

MIT © [laguser](https://github.com/laguser)

---

<p align="center">
  <sub>Built with ❤️ for people who love to write.</sub>
</p>
