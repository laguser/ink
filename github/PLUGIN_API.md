# Ink Plugin API

Ink supports a lightweight plugin system. Plugins are stored per-workspace in the `plugins/` directory and can extend the editor with custom behaviour.

---

## Plugin Structure

```
your-workspace/
  plugins/
    your-plugin-id/
      plugin.json
```

### `plugin.json`

| Field         | Type      | Default   | Description                              |
|---------------|-----------|-----------|------------------------------------------|
| `id`          | `string`  | —         | Unique identifier (kebab-case)           |
| `name`        | `string`  | —         | Display name                             |
| `description` | `string`  | `""`      | Short description shown in Settings      |
| `icon`        | `string`  | `"puzzlepiece.extension"` | SF Symbol name          |
| `version`     | `string`  | `"1.0.0"` | SemVer                                    |
| `enabled`     | `bool`    | `true`    | On/off state (overridden by user toggle) |
| `type`        | `string`  | `"local"` | `"local"` or `"cloud"`                  |

Example:

```json
{
  "id": "wordhighlighter",
  "name": "Word Highlighter",
  "description": "Highlights all occurrences of a selected word",
  "icon": "highlighter",
  "version": "1.0.0",
  "enabled": true,
  "type": "local"
}
```

---

## Plugin Manager

The `PluginManager` singleton (`PluginManager.shared`) handles:

| Method                        | Description                                       |
|------------------------------|---------------------------------------------------|
| `loadPlugins(from:)`         | Scans `plugins/` directory and loads metadata     |
| `saveEnabled(_:)`            | Persists enabled/disabled state per plugin        |
| `autocompleteSuggestions(for:in:)` | Returns word completion suggestions           |
| `highlightSelection(word:in:)` | Applies/removes text highlights from text storage |

### Flow

```
App launch
  → SidebarView.onAppear
  → PluginManager.shared.loadPlugins(from: workspaceURL)
  → reads each plugins/*/plugin.json
  → merges with saved UserDefaults enabled/disabled state
  → populates PluginManager.shared.plugins
```

---

## Built-in Plugins

### Auto Complete

| Property      | Value                            |
|---------------|----------------------------------|
| **ID**        | `autocomplete`                   |
| **Icon**      | `text.insert`                    |
| **Behaviour** | Collects words from the current document. When 2+ characters are typed at the end of a word, shows a popup with up to 8 matches. |

**Controls:**
- `Tab` — cycle through suggestions
- `Enter` — insert selected suggestion
- `Escape` — dismiss popup
- Mouse click — insert suggestion

### Word Highlighter

| Property      | Value                            |
|---------------|----------------------------------|
| **ID**        | `wordhighlighter`                |
| **Icon**      | `highlighter`                    |
| **Behaviour** | When text is selected, highlights all occurrences of the word in yellow. Highlights clear automatically on deselection. |

---

## Creating a Plugin

1. Create a folder under `{workspace}/plugins/{your-id}/`
2. Add a `plugin.json` with the required fields
3. Implement the behaviour by extending the appropriate hook in Swift

### Example: Minimal Plugin

```json
{
  "id": "myplugin",
  "name": "My Plugin",
  "description": "Does something useful",
  "icon": "star",
  "version": "1.0.0",
  "enabled": true,
  "type": "local"
}
```

> **Note:** Cloud plugins (type: `"cloud"`) are not yet supported. The Settings page shows a *Coming Soon* placeholder.

---

## Available Hooks

| Hook                     | When triggered                         | Return value                          |
|--------------------------|----------------------------------------|---------------------------------------|
| `autocompleteSuggestions(for:in:)` | On every text change          | `[String]` — suggested completions    |
| `highlightSelection(word:in:)`     | On selection change           | `Void` — applies attributes to NSTextStorage |

To add a new hook:
1. Add a method to `PluginManager`
2. Check `isPluginEnabled("your-id")`
3. Call the method from the appropriate view/viewmodel delegate

---

## State Persistence

Plugin enabled/disabled state is stored in `UserDefaults` with key `plugin_enabled_{id}`. This overrides the `enabled` field in `plugin.json` so user preferences persist across sessions.

---

## Settings UI

Plugins appear automatically in **Settings → Plugins** after loading. Each row shows the icon, name, description, and a toggle switch.
