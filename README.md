# Goose GUI for macOS

A crisp, clean, minimal native macOS UI for the [Goose CLI tool](https://github.com/square/goose). Features a Spotlight-like windowless mode with hotkey activation and a traditional window for running commands.

![Goose GUI Screenshot](docs/images/goose-main.png)

## Features

✨ **Native macOS Experience**
- Built with SwiftUI for a modern, native look and feel
- Menu bar integration for quick access
- System-wide hotkey support
- Dark mode support

🚀 **Spotlight Mode**
- Press `⌘+Shift+G` to instantly open a Spotlight-like command window
- Quick command execution without leaving your current context
- Auto-hide after command execution
- Command history with arrow keys

🖥️ **Traditional Window Mode**
- Full command output display with ANSI color support
- Command history and suggestions
- Real-time output streaming
- Resizable and customizable interface

🎯 **Smart Features**
- Command auto-completion and suggestions
- Recent command history
- Output parsing with syntax highlighting
- Clickable URLs in output
- Error detection and highlighting

## Installation

### Requirements
- macOS 13.0 (Ventura) or later
- Goose CLI tool installed (`goose` command available in PATH)

### Download
1. Download the latest release from the [Releases page](https://github.com/yourusername/goose-gui/releases)
2. Move `Goose.app` to your Applications folder
3. Launch Goose from Applications or Spotlight

### Build from Source
```bash
# Clone the repository
git clone https://github.com/yourusername/goose-gui.git
cd goose-gui

# Build using Swift Package Manager
swift build -c release

# Or open in Xcode
open Package.swift
```

## Quick Start

### First Launch
1. Launch Goose from your Applications folder
2. Grant accessibility permissions if prompted (required for global hotkeys)
3. The menu bar icon will appear

### Using Spotlight Mode
1. Press `⌘+Shift+G` from anywhere in macOS
2. Type your goose command (e.g., `goose run my-task`)
3. Press Enter to execute
4. Press Escape to dismiss

### Using Window Mode
1. Click the Goose menu bar icon
2. Select "Show Main Window"
3. Type commands in the input field
4. View output in the main area
5. Use ↑/↓ arrows to navigate command history

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘+Shift+G` | Toggle Spotlight mode |
| `⌘+K` | Clear output (in window mode) |
| `⌘+,` | Open Preferences |
| `⌘+Q` | Quit Goose |
| `↑` / `↓` | Navigate command history |
| `Tab` | Auto-complete command |
| `Escape` | Close Spotlight window |
| `⌘+Enter` | Execute in background |

## Configuration

### Preferences

Access preferences through `Goose → Preferences` or press `⌘+,`

#### General
- **Launch at Login**: Start Goose when macOS starts
- **Show in Dock**: Toggle dock icon visibility
- **Default Mode**: Choose between Window or Spotlight mode

#### Hotkeys
- Customize the global hotkey combination
- Enable/disable hotkey functionality
- Set activation delay

#### Appearance
- Theme selection (Light/Dark/Auto)
- Font size adjustment
- Output color scheme
- Window transparency

#### CLI Settings
- Goose executable path
- Environment variables
- Working directory
- Timeout settings

## Troubleshooting

### Common Issues

#### "Goose CLI not found"
- Ensure `goose` is installed and in your PATH
- Check the executable path in Preferences → CLI Settings
- Try running `which goose` in Terminal to verify installation

#### Hotkey not working
1. Go to System Settings → Privacy & Security → Accessibility
2. Ensure Goose is listed and enabled
3. If not listed, click + and add Goose.app
4. Restart Goose after granting permissions

#### Commands fail with permission errors
- Check that Goose has necessary file system permissions
- For Full Disk Access: System Settings → Privacy & Security → Full Disk Access
- Add Goose if needed for accessing protected directories

#### Output appears garbled
- Check Preferences → Appearance → Output Encoding
- Ensure it matches your system locale (usually UTF-8)
- Try toggling ANSI color support

### Debug Mode

Enable debug logging for troubleshooting:
1. Open Preferences → Advanced
2. Enable "Debug Logging"
3. Logs are saved to `~/Library/Logs/Goose/`

### Reset Settings

To reset all settings to defaults:
```bash
defaults delete com.yourcompany.Goose
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## Architecture

- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for data flow
- **Process**: System process management for CLI interaction
- **UserDefaults**: Preference storage
- **HotKey**: Global hotkey registration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Goose CLI](https://github.com/square/goose) by Square
- [HotKey](https://github.com/soffes/HotKey) for global hotkey support
- The macOS development community

## Support

- Report issues on [GitHub Issues](https://github.com/yourusername/goose-gui/issues)
- Join our [Discord community](https://discord.gg/goose)
- Check the [Wiki](https://github.com/yourusername/goose-gui/wiki) for detailed guides
