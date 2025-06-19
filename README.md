# Matrix Life Logger

A revolutionary visionOS app that transforms life logging into immersive spatial experiences. Visualize your journal entries, memories, and life patterns in 3D space using Apple Vision Pro's spatial computing capabilities.

## 🌟 Features

### ✅ Timeline River (Complete)
- **3D Spatial Visualization**: Journal entries flow through space as interactive particles
- **Hand Gesture Controls**: Tap, drag, and pinch to interact with your memories
- **Mood & Activity Color Coding**: Visual representation of emotions and activities
- **Real-time Interaction**: Select entries to view detailed information
- **Authentic Data**: Now populated with real Ann Arbor life experiences

### 🚧 In Development
- **Location Galaxy**: Terminal-style map visualization system
- **Data Import Tools**: SQLite and legacy data conversion
- **Advanced Analytics**: Pattern recognition and insights

## 🏗️ Architecture

### Core Components
- **SwiftData Models**: `JournalEntry` with mood, activity, and location data
- **RealityKit Integration**: 3D particle systems and spatial interactions
- **Gesture Systems**: Multi-touch spatial navigation
- **Data Services**: Centralized data management and loading

### Key Files
```
Matrix Life Logger/
├── Models/JournalEntry.swift          # Core data model
├── Services/DataService.swift         # Data management
├── Views/TimelineRiverView.swift      # Main 3D visualization
├── Spatial/TimelineRiverSystem.swift  # 3D rendering system
├── Spatial/GestureInteractionSystem.swift # Touch handling
└── DataImporter/                      # Import utilities
```

## 🚀 Getting Started

### Prerequisites
- Xcode 15.2+
- visionOS 2.0+ SDK
- Apple Vision Pro Simulator or device

### Installation
1. Clone the repository
2. Open `Matrix Life Logger.xcodeproj`
3. Select visionOS Simulator target
4. Build and run

### Current Build Status
- ✅ Timeline River fully functional
- ✅ Real journal data integrated
- ✅ Hand gestures working
- ✅ SwiftData models complete

## 📊 Sample Data

The app currently includes 5 real journal entries from Ann Arbor:
- Zingerman's Roadhouse family dinner
- Late-night coding at Literati Bookstore  
- Nature walk at The Arb
- Anxiety management and reflection
- Coffee house community observations

## 🎯 Roadmap

### Immediate Next Steps
1. **Location Galaxy System**
   - Terminal-style map visualization
   - Geographic clustering of entries
   - Interactive location exploration

2. **Data Import Enhancement**
   - Complete SQLite importer
   - Legacy data conversion tools
   - Bulk import capabilities

3. **Advanced Visualizations**
   - Constellation patterns for related entries
   - Time-based animations
   - Mood trend analysis

### Future Features
- Voice-to-text journal entry
- Photo integration
- Social sharing capabilities
- Export and backup systems

## 🛠️ Development

### Recent Updates
- Replaced placeholder data with authentic journal entries
- Fixed Combine framework import issues
- Enhanced location data with real coordinates
- Improved gesture interaction systems

### Building
```bash
cd "Matrix Life Logger"
xcodebuild -project "Matrix Life Logger.xcodeproj" \
  -scheme "Matrix Life Logger" \
  -destination "platform=visionOS Simulator,name=Apple Vision Pro 4K" \
  build
```

## 📱 visionOS Integration

- **Immersive Spaces**: Full 3D environment for data exploration
- **Hand Tracking**: Natural gesture-based navigation
- **Spatial Audio**: Audio feedback for interactions
- **Eye Tracking**: Gaze-based selection (planned)

## 🤝 Contributing

This project uses a structured development approach:
1. Each major feature gets its own branch
2. All changes are committed with clear roadmap updates
3. Code is documented for future development sessions

## 📄 License

Private project - Matrix Life Logger visionOS App

---

**Current Status**: Timeline River complete ✅ | Next: Location Galaxy 🌌