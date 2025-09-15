# Contributing to Goose GUI

Thank you for your interest in contributing to Goose GUI! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Architecture Overview](#architecture-overview)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Style Guide](#style-guide)
- [Documentation](#documentation)

## Code of Conduct

Please be respectful and constructive in all interactions. We welcome contributors of all experience levels and backgrounds.

## Getting Started

### Prerequisites

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- Git
- Goose CLI installed (for testing)

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork:
```bash
git clone https://github.com/yourusername/goose-gui.git
cd goose-gui
```

3. Add the upstream remote:
```bash
git remote add upstream https://github.com/originalowner/goose-gui.git
```

## Development Setup

### Using Xcode

1. Open the project in Xcode:
```bash
open Package.swift
```

2. Select the Goose scheme
3. Build and run (⌘+R)

### Using Command Line

```bash
# Build the project
swift build

# Run tests
swift test

# Build for release
swift build -c release
```

### Project Structure

```
goose-gui/
├── Goose/
│   ├── Goose/               # Main application code
│   │   ├── Models/          # Data models
│   │   ├── Views/           # SwiftUI views
│   │   ├── ViewModels/      # View models (MVVM)
│   │   ├── Services/        # Business logic and utilities
│   │   └── GooseApp.swift   # App entry point
│   ├── GooseTests/          # Unit tests
│   └── GooseUITests/        # UI tests
├── Package.swift            # Swift package manifest
├── README.md               # User documentation
└── CONTRIBUTING.md         # This file
```

## Architecture Overview

### Design Patterns

- **MVVM (Model-View-ViewModel)**: Separation of concerns for UI logic
- **Combine Framework**: Reactive programming for data binding
- **Dependency Injection**: Testability and modularity

### Key Components

#### Services
- `CommandExecutor`: Manages CLI process execution
- `CommandSuggestionProvider`: Provides command auto-completion
- `HotkeyManager`: Handles global hotkey registration
- `MenuBarManager`: Manages menu bar presence
- `OutputParser`: Parses and formats CLI output
- `SpotlightWindowManager`: Controls Spotlight-like window

#### ViewModels
- `CommandInputViewModel`: Handles command input logic
- `MainWindowViewModel`: Manages main window state

#### Views
- `MainWindow`: Primary application window
- `SpotlightWindow`: Spotlight-style command window
- `PreferencesWindow`: Settings and configuration
- `CommandOutputView`: Displays command output

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-xyz` - New features
- `fix/issue-123` - Bug fixes
- `docs/update-readme` - Documentation
- `refactor/improve-parser` - Code refactoring

### Development Workflow

1. Create a new branch:
```bash
git checkout -b feature/your-feature
```

2. Make your changes
3. Write/update tests
4. Update documentation
5. Commit with clear messages

### Commit Messages

Follow conventional commit format:
```
type(scope): description

[optional body]

[optional footer]
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `chore`: Maintenance tasks

Example:
```
feat(spotlight): add command history navigation

- Add up/down arrow key support
- Store last 50 commands
- Persist history between sessions
```

## Testing

### Unit Tests

Located in `Goose/GooseTests/`

```bash
# Run all tests
swift test

# Run specific test
swift test --filter CommandExecutorTests
```

### UI Tests

Located in `Goose/GooseUITests/`

Run UI tests in Xcode:
1. Select the GooseUITests scheme
2. Run tests (⌘+U)

### Writing Tests

- Aim for >70% code coverage for business logic
- Mock external dependencies
- Test edge cases and error conditions
- Use descriptive test names

Example test:
```swift
func testCommandExecutionWithValidInput() async throws {
    // Arrange
    let executor = CommandExecutor()
    let expectation = XCTestExpectation(description: "Command completes")
    
    // Act
    let result = await executor.execute(command: "echo", arguments: ["test"]) { output in
        // Assert
        XCTAssertEqual(output, "test\n")
        expectation.fulfill()
    }
    
    await fulfillment(of: [expectation], timeout: 5.0)
    XCTAssertTrue(result)
}
```

## Submitting Changes

### Pull Request Process

1. Update your fork:
```bash
git fetch upstream
git checkout main
git merge upstream/main
```

2. Rebase your feature branch:
```bash
git checkout feature/your-feature
git rebase main
```

3. Push to your fork:
```bash
git push origin feature/your-feature
```

4. Create a Pull Request on GitHub

### PR Guidelines

- Provide a clear description of changes
- Reference any related issues
- Include screenshots for UI changes
- Ensure all tests pass
- Update documentation as needed

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] UI tests pass (if applicable)
- [ ] Manual testing completed

## Screenshots (if applicable)
[Add screenshots here]

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No new warnings
```

## Style Guide

### Swift Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and use SwiftLint for enforcement.

Key points:
- Use descriptive names
- Prefer clarity over brevity
- Use `let` over `var` when possible
- Avoid force unwrapping
- Document public APIs

### SwiftLint

Install SwiftLint:
```bash
brew install swiftlint
```

Run SwiftLint:
```bash
swiftlint
```

Configuration is in `.swiftlint.yml`

### Code Organization

- Group related functionality
- Use extensions for protocol conformance
- Keep files focused and under 400 lines
- Use MARK comments for organization:

```swift
// MARK: - Properties
// MARK: - Lifecycle
// MARK: - Public Methods
// MARK: - Private Methods
// MARK: - Actions
```

## Documentation

### Code Documentation

Document all public APIs using Swift documentation comments:

```swift
/// Executes a command with the given arguments
/// - Parameters:
///   - command: The command to execute
///   - arguments: Array of command arguments
///   - output: Closure called with output lines
/// - Returns: True if execution succeeded
public func execute(
    command: String,
    arguments: [String],
    output: @escaping (String) -> Void
) async -> Bool {
    // Implementation
}
```

### README Updates

Update README.md when:
- Adding new features
- Changing requirements
- Modifying installation steps
- Adding keyboard shortcuts

### Wiki

For extensive documentation, consider adding to the GitHub Wiki:
- Architecture deep dives
- Troubleshooting guides
- Advanced configuration
- Development tutorials

## Getting Help

- Open an issue for bugs or feature requests
- Join discussions in GitHub Discussions
- Ask questions in pull requests
- Contact maintainers directly for sensitive issues

## Recognition

Contributors are recognized in:
- The README.md acknowledgments section
- Release notes
- The application's About window

Thank you for contributing to Goose GUI!
