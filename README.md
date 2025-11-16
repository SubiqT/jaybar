# jaybar

A Flutter-powered status bar for yabai.

## Features

- Lightweight status bar replacement
- Built with Flutter for native performance
- Customizable and extensible

## Installation

### Development
```bash
flutter pub get
flutter run
```

### Distribution
1. Build the app:
```bash
flutter build macos --release
```

2. Install the app:
```bash
cp -r build/macos/Build/Products/Release/jaybar.app /Applications/
```

3. Add to PATH (optional, for CLI access):
```bash
echo 'export PATH="/Applications/jaybar.app/Contents/MacOS:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

4. Enable and start the service:
```bash
jaybar --enable-service
jaybar --start-service
```

### CLI Usage
```bash
jaybar                    # Start the status bar GUI
jaybar --start-service    # Start the jaybar service
jaybar --stop-service     # Stop the jaybar service  
jaybar --restart-service  # Restart the jaybar service
jaybar --enable-service   # Enable the launch agent
jaybar --disable-service  # Disable the launch agent
jaybar --help             # Show help message
```

### Manual Service Management
```bash
# Stop service
launchctl unload ~/Library/LaunchAgents/com.jaybar.plist

# Start service  
launchctl load ~/Library/LaunchAgents/com.jaybar.plist
```

## Development

This project uses Flutter. Make sure you have Flutter installed and configured for macOS development.

## License

MIT
