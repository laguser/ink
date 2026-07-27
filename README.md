
![Ink](https://img.shields.io/badge/Ink-markdown%20editor-1d1d1f?style=flat-square)
![macOS](https://img.shields.io/badge/macOS-14%2B-lightgrey?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square)

<p align="center">
  <img src="https://img.shields.io/badge/✍%20Minimalist%20Markdown%20Editor-1d1d1f?style=for-the-badge" alt="Ink">
</p>

<div align="center">

**Ink** is a minimalist, distraction-free Markdown editor for macOS.  
Built with SwiftUI and AppKit. No chrome, no clutter — just you and your words.

</div>

---

## Features

- **Distraction-free writing** — hidden title bar, full-size content view, no tabs
- **Programmatic keyboard sounds** — synthetic click sounds (like iOS keyboard) with adjustable pitch, duration, and noise
- **Live Markdown preview** — rendered in a WKWebView with proper styling (headings, bold, italic, lists, code blocks, quotes, tables, links, images)
- **Workspace management** — multiple workspaces, each is a plain folder of `.md` files
- **Plugin system** — extend functionality with local plugins (Auto Complete, Word Highlighter)
- **Language support** — English, Russian, Japanese (switched in Settings)
- **Custom cursor** — block / line / underline with pixel editor, adjustable width and colour
- **Export** — TXT, PDF, Markdown with folder export
- **Animation** — configurable slide / fade / scale animation for document switching
- **Keyboard shortcuts** — fully customizable in Settings → Shortcuts

---

## Screenshots

*Coming soon — the app is in active development.*

---

## Quick Start

1. Clone and build:
   ```bash
   git clone https://github.com/your-username/ink.git
   cd ink
   swift build
   ```

2. Or run directly:
   ```bash
   swift run
   ```

3. On first launch, Ink will ask you to choose a workspace folder.  
   All notes are saved as plain `.md` files in that folder.

---

## Keyboard Shortcuts

| Shortcut               | Action              | Customisable |
|------------------------|---------------------|:------------:|
| `⌘N`                  | New Document        | ✅           |
| `⌘S`                  | Save                | ✅           |
| `⌘,`                  | Settings            | ✅           |
| `⌘⇧P`                 | Toggle Preview      | ✅           |
| `⌘⇧S`                 | Toggle Sidebar      | ✅           |

All shortcuts are remappable in **Settings → Shortcuts**.

---

## Plugin API

Ink supports a plugin system. Plugins are stored in `{workspace}/plugins/{id}/plugin.json`.

| Plugin              | Description                                      |
|---------------------|--------------------------------------------------|
| **Auto Complete**   | Suggests word completions as you type (Tab/Enter to navigate) |
| **Word Highlighter**| Highlights all occurrences of a selected word with yellow |

Full API reference → [`github/PLUGIN_API.md`](github/PLUGIN_API.md)

---

## Workspaces

Workspaces are plain directories of Markdown files. You can:

- **Create** a new workspace on first launch
- **Add** an existing folder of `.md` files
- **Switch** between workspaces from the sidebar footer
- **Open in Finder** directly from the workspace menu
- **Remove** a workspace from the list

Documents are named after their title and saved as `{Title}.md`.

---

## Settings

Access settings via `⌘,` or the menu.

| Section       | Options                                                                 |
|---------------|-------------------------------------------------------------------------|
| General       | Font, font size, line height, auto-save, spell check, theme             |
| Sound         | Volume, pitch, duration, noise, custom sound files per character type   |
| Typography    | Line height, paragraph spacing                                          |
| Animation     | Transition style (slide/fade/scale/none), duration (0.1–1.0s)           |
| Cursor        | Shape (block/line/underline/custom), width, colour, pixel editor 8×16   |
| Shortcuts     | Remap any keyboard shortcut                                             |
| Plugins       | Enable/disable plugins                                                  |
| Language      | English / Русский / 日本語                                              |
| Export        | Export current document or all documents                                |

---

## Building from Source

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run with build script
./build_and_run.sh
```

- **macOS 14+** required
- No external dependencies — pure SwiftUI + AppKit

---

## Tech Stack

| Layer   | Technology               |
|---------|--------------------------|
| UI      | SwiftUI + AppKit hybrid  |
| Editor  | NSTextView subclass      |
| Preview | WKWebView + custom Markdown→HTML converter |
| Storage | JSON (`Application Support/Ink/`) + plain `.md` files |
| Sounds  | Programmatic sine-wave synthesis (CoreAudio) |

---

## License

MIT © Nicolay

---

<div align="center">
  <sub>Built with ❤️ for people who love to write.</sub>
</div>
