# Matrix Life Logger 🥽 ✨

> Transform your life data into immersive spatial experiences on Apple Vision Pro

[![visionOS 2.0+](https://img.shields.io/badge/visionOS-2.0+-black?style=flat-square&logo=apple)](https://developer.apple.com/visionos/)
[![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange?style=flat-square&logo=swift)](https://swift.org)
[![RealityKit](https://img.shields.io/badge/RealityKit-Powered-blue?style=flat-square)](https://developer.apple.com/documentation/realitykit/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)

Matrix Life Logger brings Wei's Life Logger into the spatial computing era. Experience your personal data as never before - walk through your memories, reach out and touch your activities, and explore your life's journey in full 3D immersion.

![Matrix Life Logger Demo](docs/images/hero-banner.png)

## 🌟 Features

### 🌊 **Timeline River**
Float through your life events as a flowing river of memories. Each entry becomes a glowing particle you can interact with using natural hand gestures.

### 🌌 **Location Galaxy** 
Your visited locations transform into a personal galaxy. Frequently visited places become larger celestial bodies, with activities orbiting around them like planets.

### ✨ **Activity Constellation**
See how your activities connect in 3D space. Related activities form constellations with particle effects showing the strength of connections.

### 🏛️ **Memory Palace**
Step inside your memories. Walk through spatially-anchored journal entries with photos floating as holograms around you.

## 📱 Requirements

- Apple Vision Pro or visionOS Simulator
- visionOS 2.0 or later
- Xcode 15.2 or later
- macOS Sonoma 14.0 or later
- 8GB free space for immersive content

## 🚀 Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/matrix-life-logger.git
cd matrix-life-logger
```

2. **Open in Xcode**
```bash
open MatrixLifeLogger.xcodeproj
```

3. **Select Vision Pro destination**
   - Choose your connected Vision Pro or
   - Select "Apple Vision Pro Simulator"

4. **Build and Run**
   - Press `Cmd + R` or click the Run button
   - Grant necessary permissions when prompted

## 🔄 Importing from Wei's Life Logger

If you have existing data from Wei's Life Logger:

1. Export your SQLite database from Wei's Life Logger
2. Place it in `~/Documents/MatrixLifeLogger/Import/`
3. Launch Matrix Life Logger
4. Navigate to Settings → Import Data
5. Select your database file
6. Watch as your data transforms into spatial visualizations

## 🤲 Hand Gestures Guide

| Gesture | Action |
|---------|--------|
| 👌 **Pinch** | Select/activate elements |
| 🤏 **Pinch & Drag** | Move objects in space |
| 🖐️ **Spread** | Expand visualizations |
| 👉 **Point & Hold** | View entry details |
| 👏 **Clap** | Enter immersive mode |
| ✊ **Fist** | Reset view |
| 🤚 **Palm Open** | Pause animations |

## 🏗️ Architecture

```
MatrixLifeLogger/
├── 📱 App/                    # Main application
├── 🎨 Spatial/               # 3D visualizations
├── 📊 Models/                # Data models
├── 🔧 Services/              # Business logic
├── 🌐 Views/                 # UI components
│   ├── Windows/             # 2D windows
│   ├── Volumes/             # 3D volumes
│   └── Immersive/           # Full spaces
└── 📦 Resources/             # Assets
```

## 🛠️ Development

### Prerequisites

- Install Xcode 15.2+
- Install visionOS SDK
- (Optional) Physical Vision Pro device

### Building from Source

```bash
# Clone with submodules
git clone --recursive https://github.com/yourusername/matrix-life-logger.git

# Install dependencies
cd matrix-life-logger
swift package resolve

# Build
xcodebuild -scheme MatrixLifeLogger -configuration Debug

# Run tests
xcodebuild test -scheme MatrixLifeLogger
```

### Creating Custom Visualizations

```swift
class MyCustomVisualization: VisualizationPlugin {
    var identifier: String { "com.myapp.customviz" }
    
    func createVisualization(for entries: [JournalEntry]) -> Entity {
        // Your 3D visualization logic here
    }
}

// Register your visualization
VisualizationRegistry.shared.register(MyCustomVisualization())
```

## 📊 Performance Guidelines

- Target 90 FPS for comfort
- Keep particle count under 10,000
- Use LOD for distant objects
- Implement frustum culling
- Monitor thermal state

## 🔐 Privacy & Security

- **Local First**: All data processing happens on-device
- **No Cloud Sync**: Unless explicitly enabled via CloudKit
- **Encrypted Storage**: SwiftData with encryption
- **Spatial Privacy**: No location data leaves your device
- **Secure Anchors**: World anchors use local coordinates only

## 🐛 Troubleshooting

### Spatial tracking issues
```swift
// Reset tracking if lost
SpatialTrackingManager.shared.reset()
```

### Performance problems
- Reduce particle effects in Settings
- Disable shadows for better performance
- Use simplified visualization mode

### Import failures
- Ensure SQLite file is not corrupted
- Check file permissions
- Verify data format compatibility

## 📖 Documentation

- [User Guide](docs/USER_GUIDE.md)
- [Developer Guide](docs/DEVELOPER_GUIDE.md)
- [API Reference](docs/API_REFERENCE.md)
- [Spatial UI Guidelines](docs/SPATIAL_UI_GUIDELINES.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📅 Roadmap

- [ ] Collaborative spaces for shared memories
- [ ] AI-powered insights with Core ML
- [ ] Haptic feedback integration
- [ ] Voice journaling in space
- [ ] Cross-platform sync
- [ ] Time machine mode

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Original [Wei's Life Logger](https://github.com/wei/life-logger) by Wei
- Apple's visionOS team for the amazing platform
- The spatial computing community

## 📞 Support

- 📧 Email: support@matrixlifelogger.com
- 💬 Discord: [Join our server](https://discord.gg/matrixll)
- 🐦 Twitter: [@MatrixLifeLog](https://twitter.com/matrixlifelog)
- 📹 YouTube: [Tutorials](https://youtube.com/matrixlifelogger)

---

## 🤖 Claude Code Changelog

This section tracks all code modifications made by Claude AI to ensure transparency and maintainability.

### Version 1.0.0 (Initial Release) - June 2025
**Created by Claude (Anthropic)**
- ✨ Initial spatial adaptation of Wei's Life Logger
- 🏗️ Complete visionOS architecture design
- 🌊 Implemented Timeline River visualization
- 🌌 Created Location Galaxy immersive space  
- ✨ Built Activity Constellation view
- 🏛️ Designed Memory Palace experience
- 🤲 Integrated hand tracking gestures
- 📊 Added spatial data models
- 🔐 Implemented privacy-first architecture

### Future Claude Updates
When Claude makes updates to this codebase, document them here with:
- Date of modification
- Claude conversation ID (if available)
- List of changed files
- Description of changes
- Reasoning for modifications

```markdown
### Version X.X.X - [Date]
**Modified by Claude**
- Changed files:
  - `path/to/file1.swift` - [Description]
  - `path/to/file2.swift` - [Description]
- Reasoning: [Why these changes were made]
- Testing: [How changes were validated]
- Breaking changes: [If any]
```

### Claude Integration Guidelines
When asking Claude to modify the code:
1. Always request updates to this changelog
2. Specify the context of changes needed
3. Ask for reasoning documentation
4. Request test cases for new features
5. Ensure backwards compatibility notes

### Tracking Claude Contributions
```yaml
# .claude-tracking.yml
version: 1.0.0
last_updated: 2025-06-19
total_modifications: 1
contributors:
  - type: "Claude AI"
    model: "claude-3-opus"
    sessions:
      - date: "2025-06-19"
        changes: ["Initial creation"]
        files_affected: ["All files"]
```

---

<p align="center">
Made with 🤖 by Claude and ❤️ by humans<br>
Building the future of spatial life logging
</p>