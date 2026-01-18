# Clipboard

A lightweight clipboard history manager for macOS. Keep track of everything you copy with quick access via global hotkey.

**[中文文档](README.zh-CN.md)**

## Screenshot

![Clipboard Demo](Assets/demo.png)

## Features

- **Clipboard History** - Automatically saves your clipboard history (text, images, and files)
- **Global Hotkey** - Press `⌃⌘V` to instantly open the clipboard manager (customizable)
- **Fuzzy Search** - Find what you need with intelligent fuzzy matching (exact, acronym, prefix, and approximate matching)
- **Preview Panel** - Hover over any item to preview its full content
- **Multi-Language Support** - English and Chinese (Simplified)
- **Image Support** - Automatic thumbnail generation for images
- **File Detection** - Recognizes and displays file references

## Requirements

- macOS 15.0 or later
- Accessibility permissions (for global hotkey)

## Building from Source

### Prerequisites

- Xcode 16.0 or later, OR
- Swift 6.0+ toolchain with Swift Package Manager

### Build with Swift Package Manager

```bash
# Clone the repository
git clone https://github.com/hcjcch/Clipboard.git
cd Clipboard

# Build the project
swift build

# Run the application
swift run
```

### Build with Xcode

```bash
# Generate and open Xcode project
swift package generate-xcodeproj
open Clipboard.xcodeproj

# Or open directly (Xcode 16+)
open Package.swift
```

Then build and run from Xcode (Product > Run, or `⌘R`).

## First Run

On first launch, you'll need to grant Accessibility permissions:

1. Go to **System Settings** > **Privacy & Security** > **Accessibility**
2. Click the lock icon to unlock
3. Find "Clipboard" in the list and enable it

## Usage

- **Show/Hide**: Press `⌃⌘V` (Control + Command + V)
- **Search**: Type to filter your clipboard history
- **Select**: Use arrow keys or mouse
- **Copy**: Press Enter to copy selected item to clipboard
- **Preview**: Hover over an item to see full content
- **Clear Search**: Press Escape
- **Settings**: Click the gear icon in the menu bar

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
