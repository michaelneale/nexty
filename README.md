# Goose GUI

A clean, minimal native macOS UI for the Goose CLI tool with Spotlight-like popup functionality.

## Features

- Native SwiftUI interface for macOS 13.0+
- Clean, minimal design
- Command execution interface for Goose CLI
- Spotlight-like popup window (hotkey activation coming in next phase)
- Window management for running commands

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Build Instructions

### Using Xcode

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Open the project in Xcode:
```bash
open Goose.xcodeproj
```
Or double-click the `Goose.xcodeproj` file in Finder.

3. Build and run:
   - Select the Goose scheme
   - Choose your Mac as the run destination
   - Press `Cmd+R` or click the Run button

### Using Swift Package Manager (Command Line)

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Build the project:
```bash
swift build
```

3. Run the app:
```bash
swift run
```

## Project Structure

```
Goose/
├── Goose/                    # Main app target
│   ├── GooseApp.swift       # App entry point
│   ├── ContentView.swift    # Main content view
│   ├── Views/              # UI components
│   ├── Models/             # Data models
│   ├── Services/           # Business logic and CLI integration
│   ├── Resources/          # Additional resources
│   ├── Assets.xcassets/    # Images and colors
│   ├── Info.plist          # App configuration
│   └── Goose.entitlements  # App permissions
├── GooseTests/             # Unit tests
├── GooseUITests/           # UI tests
└── Package.swift           # Swift Package Manager configuration
```

## Development

### Architecture

The app uses SwiftUI for the UI layer and follows MVVM architecture:
- **Views**: SwiftUI views for the interface
- **Models**: Data structures for commands and results
- **Services**: CLI integration and command execution

### Key Components

- **GooseApp.swift**: Main app entry point with window management
- **ContentView.swift**: Primary interface for command input and output
- **AppDelegate**: Handles app lifecycle and global hotkey registration (coming soon)

### Entitlements

The app requires the following entitlements:
- Process execution (for CLI integration)
- File system access (for reading/writing configurations)
- Network access (for potential remote operations)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

[License information to be added]

## Support

For issues and questions, please open an issue in the repository.

---

**Note**: This is the foundational setup. Additional features including:
- Goose CLI integration
- Global hotkey activation
- Spotlight-like popup window
- Command history and favorites

Will be added in subsequent development phases.
