# Build and Release Instructions

This document provides detailed instructions for building and releasing Goose GUI.

## Table of Contents

- [Development Build](#development-build)
- [Release Build](#release-build)
- [Code Signing](#code-signing)
- [Creating a Release](#creating-a-release)
- [Distribution](#distribution)
- [Troubleshooting](#troubleshooting)

## Development Build

### Using Xcode

1. Open the project:
```bash
open Package.swift
```

2. Select the Goose scheme from the scheme selector
3. Choose your target device (Mac)
4. Build and run: Press `⌘+R` or click the Run button

### Using Command Line

```bash
# Debug build
swift build

# Run the debug build
.build/debug/Goose

# Run tests
swift test

# Clean build artifacts
swift package clean
```

### Build Configuration

The debug build includes:
- Debug symbols
- Assertions enabled
- Optimization disabled
- Console logging

## Release Build

### Command Line Build

```bash
# Build for release
swift build -c release

# The binary will be at:
# .build/release/Goose
```

### Xcode Archive

1. Open project in Xcode
2. Select Product → Archive
3. Wait for the archive to complete
4. The Organizer window will open with your archive

### Creating an App Bundle

To create a proper macOS app bundle:

```bash
# Create app structure
mkdir -p Goose.app/Contents/MacOS
mkdir -p Goose.app/Contents/Resources

# Copy executable
cp .build/release/Goose Goose.app/Contents/MacOS/

# Create Info.plist
cat > Goose.app/Contents/Info.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Goose</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.Goose</string>
    <key>CFBundleName</key>
    <string>Goose</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Add icon (if you have one)
# cp YourIcon.icns Goose.app/Contents/Resources/
```

## Code Signing

### Developer ID Certificate

For distribution outside the App Store:

1. Obtain a Developer ID certificate from Apple Developer Portal
2. Install the certificate in Keychain Access

### Signing the App

```bash
# Find your identity
security find-identity -v -p codesigning

# Sign the app
codesign --force --deep --sign "Developer ID Application: Your Name (TEAMID)" Goose.app

# Verify the signature
codesign --verify --verbose Goose.app
```

### Notarization

For macOS 10.15+, apps must be notarized:

```bash
# Create a zip for notarization
ditto -c -k --keepParent Goose.app Goose.zip

# Submit for notarization
xcrun notarytool submit Goose.zip \
    --apple-id your@email.com \
    --team-id YOURTEAMID \
    --password @keychain:AC_PASSWORD \
    --wait

# Staple the ticket
xcrun stapler staple Goose.app
```

## Creating a Release

### Version Numbering

Follow semantic versioning (MAJOR.MINOR.PATCH):
- MAJOR: Breaking changes
- MINOR: New features, backwards compatible
- PATCH: Bug fixes

### Release Checklist

1. **Update version numbers:**
   - Package.swift
   - Info.plist (if using app bundle)
   - README.md

2. **Update documentation:**
   - CHANGELOG.md
   - README.md for new features
   - Screenshots if UI changed

3. **Test thoroughly:**
   ```bash
   # Run all tests
   swift test
   
   # Build release version
   swift build -c release
   
   # Manual testing checklist
   - [ ] App launches
   - [ ] Hotkeys work
   - [ ] Commands execute
   - [ ] Preferences save
   - [ ] No crashes
   ```

4. **Create git tag:**
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

### GitHub Release

1. Go to repository → Releases → Draft a new release
2. Choose the tag you created
3. Title: "Goose v1.0.0"
4. Description should include:
   - What's new
   - Bug fixes
   - Known issues
   - Download instructions
5. Attach the built artifacts:
   - Goose.app.zip (notarized)
   - Goose-v1.0.0.dmg (optional)

### Creating a DMG

```bash
# Install create-dmg (if not installed)
brew install create-dmg

# Create DMG
create-dmg \
  --volname "Goose Installer" \
  --volicon "YourIcon.icns" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "Goose.app" 175 120 \
  --hide-extension "Goose.app" \
  --app-drop-link 425 120 \
  "Goose-v1.0.0.dmg" \
  "Goose.app"
```

## Distribution

### Direct Download

1. Upload to GitHub Releases
2. Provide direct download link in README
3. Include installation instructions

### Homebrew (Optional)

Create a formula:

```ruby
class Goose < Formula
  desc "Native macOS UI for Goose CLI"
  homepage "https://github.com/yourusername/goose-gui"
  url "https://github.com/yourusername/goose-gui/releases/download/v1.0.0/Goose-v1.0.0.tar.gz"
  sha256 "YOUR_SHA256_HERE"
  version "1.0.0"

  depends_on :macos => :ventura

  def install
    app = "Goose.app"
    prefix.install app
    bin.write_exec_script "#{prefix}/#{app}/Contents/MacOS/Goose"
  end
end
```

### App Store (Future)

Requirements for App Store:
- App Sandbox enabled
- App Store Connect account
- App review guidelines compliance
- In-app purchase setup (if applicable)

## Troubleshooting

### Build Errors

**Swift version mismatch:**
```bash
# Check Swift version
swift --version

# Update to required version
# Install from https://swift.org/download/
```

**Missing dependencies:**
```bash
# Clean and fetch dependencies
swift package clean
swift package resolve
```

**Xcode issues:**
```bash
# Clear derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Reset package caches
swift package reset
```

### Signing Issues

**Certificate not found:**
- Check Keychain Access for valid certificates
- Ensure certificate is not expired
- Download from Apple Developer Portal if needed

**Notarization failures:**
- Check that all binaries are signed
- Ensure entitlements are correct
- Review notarization log for specific issues

### Runtime Issues

**App won't launch:**
- Check Console.app for crash logs
- Verify code signature: `codesign -v Goose.app`
- Check Gatekeeper: `spctl -a -v Goose.app`

**Permissions issues:**
- Reset permissions in System Settings
- Check entitlements file
- Verify app sandbox settings

## Continuous Integration

The GitHub Actions workflow automatically:
1. Builds the project for each commit
2. Runs tests
3. Creates artifacts for successful builds
4. Can be configured to create releases automatically

See `.github/workflows/tests.yml` for CI configuration.

## Support

For build issues:
- Check existing [GitHub Issues](https://github.com/yourusername/goose-gui/issues)
- Review build logs carefully
- Ask in discussions or create new issue with:
  - macOS version
  - Xcode version
  - Swift version
  - Complete error message
  - Steps to reproduce
