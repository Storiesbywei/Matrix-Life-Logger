# 🤖 CLAUDE_STARTUP_GUIDE.md - Matrix Life Logger Initial Setup

> **For .NET Developers & AI Agents Setting Up Their First visionOS Project**

---

## 🚨 BEFORE YOU START - SECURITY CHECKLIST

### Remove These Files IMMEDIATELY After Cloning:
```bash
# These files should NEVER exist in your repo
rm -rf ~/Downloads/wei_personal_data.json
rm -rf ./journal_exports/*.json
rm -rf ./journal_db/*.db
rm -rf .env
rm -rf secrets.plist
rm -rf GoogleService-Info.plist
rm -rf AuthKey_*.p8
```

### Secrets That Will Make You Look Dumb If Committed:
- ❌ API Keys (even "test" ones)
- ❌ Personal journal entries
- ❌ Location history data
- ❌ Photos with EXIF data
- ❌ .DS_Store files (macOS junk)
- ❌ xcuserdata (Xcode personal settings)
- ❌ DerivedData (Xcode build cache)
- ❌ Pods/ (if using CocoaPods)
- ❌ .env files
- ❌ Any file with "secret", "private", or "key" in the name

---

## 🎯 PROJECT INITIALIZATION STEPS

### 1. Create GitHub Repository (The Right Way™)

```bash
# Step 1: Create local project directory
mkdir MatrixLifeLogger
cd MatrixLifeLogger

# Step 2: Initialize git BEFORE creating Xcode project
git init
echo "# Matrix Life Logger" > README.md

# Step 3: Add .gitignore FIRST (see bottom of this guide)
curl -o .gitignore https://raw.githubusercontent.com/github/gitignore/main/Swift.gitignore
# Then add our custom ignores (see section below)

# Step 4: Make first commit
git add .
git commit -m "Initial commit with proper .gitignore"

# Step 5: Create Xcode project
# Open Xcode > Create New Project > visionOS App
# IMPORTANT: Save it in the MatrixLifeLogger folder you just created

# Step 6: Commit Xcode project
git add .
git commit -m "Add visionOS project structure"

# Step 7: Create GitHub repo and push
gh repo create MatrixLifeLogger --public --source=. --remote=origin --push
```

### 2. Project Structure Setup

```bash
# Create required directories
mkdir -p MatrixLifeLogger/Services
mkdir -p MatrixLifeLogger/Models
mkdir -p MatrixLifeLogger/Views/Windows
mkdir -p MatrixLifeLogger/Views/Volumes  
mkdir -p MatrixLifeLogger/Views/Immersive
mkdir -p MatrixLifeLogger/Spatial/Entities
mkdir -p MatrixLifeLogger/Spatial/Systems
mkdir -p MatrixLifeLogger/Resources/USDZ
mkdir -p MatrixLifeLogger/DataImporter
mkdir -p Documentation
mkdir -p Scripts

# Create placeholder files
touch .env.example
echo "# Add your environment variables here" > .env.example
echo "# DO NOT add real values!" >> .env.example

touch Scripts/setup.sh
chmod +x Scripts/setup.sh
```

---

## 📚 XCODE FOR .NET DEVELOPERS - TRANSLATION GUIDE

### Concept Mapping: .NET → Xcode

| .NET/Visual Studio | Xcode Equivalent | What It Does |
|-------------------|------------------|--------------|
| Solution (.sln) | Workspace (.xcworkspace) | Container for multiple projects |
| Project (.csproj) | Project (.xcodeproj) | Build configuration & file references |
| NuGet Packages | Swift Package Manager | Dependency management |
| App.config | Info.plist | App configuration & permissions |
| Program.cs | AppName.swift | App entry point |
| Forms/XAML | SwiftUI Views | UI definitions |
| ViewModels | ObservableObject classes | Data binding |
| Controllers | View Controllers (deprecated) | Use SwiftUI Views instead |
| bin/obj folders | DerivedData | Build outputs (git ignored!) |

### Understanding Xcode Project Navigator

```
🗂️ MatrixLifeLogger.xcodeproj (like your .csproj)
├── 📱 MatrixLifeLogger (main target - like your startup project)
│   ├── 🏃 MatrixLifeLoggerApp.swift (like Program.cs)
│   ├── 🖼️ ContentView.swift (like MainWindow.xaml)
│   ├── 📁 Models/ (like your Models folder)
│   ├── 📁 Views/ (like your Views folder)
│   ├── 📁 Services/ (like your Services/Business Logic)
│   └── 📋 Info.plist (like app.config)
├── 🧪 MatrixLifeLoggerTests (unit test target)
└── 🎯 Products (build outputs - like bin/)
```

### File Types You'll Encounter

| Extension | Purpose | .NET Equivalent |
|-----------|---------|-----------------|
| .swift | Swift source code | .cs files |
| .swiftui | SwiftUI view (rare) | .xaml files |
| .xib/.storyboard | Old UI files (ignore for visionOS) | .xaml (legacy) |
| .plist | Property lists (XML config) | .config files |
| .xcassets | Asset catalogs (images, colors) | Resources folder |
| .usdz | 3D models | .fbx/.obj files |
| .metal | GPU shaders | .hlsl files |

---

## 🛠️ ESSENTIAL XCODE OPERATIONS

### Building the Project
```bash
# Command line build (like dotnet build)
xcodebuild -scheme MatrixLifeLogger -configuration Debug

# Or in Xcode:
# Cmd+B = Build (like Ctrl+Shift+B in VS)
# Cmd+R = Run (like F5 in VS)
# Cmd+. = Stop (like Shift+F5 in VS)
```

### Common Xcode Shortcuts (VS → Xcode)
- `F12` → `Cmd+Click`: Go to definition
- `Ctrl+.` → `Cmd+Shift+A`: Quick actions
- `Ctrl+Space` → `Esc`: Auto-complete
- `F2` → `Cmd+Ctrl+E`: Rename everywhere
- `Ctrl+K,D` → `Ctrl+I`: Format code

### Managing Dependencies
```swift
// Package.swift (like packages.config)
dependencies: [
    .package(url: "https://github.com/example/package", from: "1.0.0")
]

// In Xcode: File > Add Package Dependencies (like Manage NuGet Packages)
```

---

## 🚀 RUNNING YOUR FIRST BUILD

### Step-by-Step for .NET Developers:

1. **Open the Project**
   ```bash
   cd MatrixLifeLogger
   open MatrixLifeLogger.xcodeproj
   ```

2. **Select Target Device** (like selecting Debug/Release in VS)
   - Top bar: Click scheme dropdown
   - Choose "Apple Vision Pro Simulator"

3. **Fix Signing** (like strong naming in .NET)
   - Click project name in navigator
   - Select "Signing & Capabilities"
   - Change "Team" to your Apple ID
   - Let Xcode create provisioning profile

4. **Build and Run**
   - Press `Cmd+R` (like F5)
   - Wait for simulator to boot
   - Your app appears in visionOS!

---

## 📝 ADDING YOUR FIRST SPATIAL VIEW

### Create a Simple Spatial View (like creating a UserControl)

1. **Right-click on Views folder > New File**
2. **Choose: SwiftUI View**
3. **Name it: MySpatialView.swift**

```swift
import SwiftUI
import RealityKit

struct MySpatialView: View {
    var body: some View {
        RealityView { content in
            // Like adding controls to a Panel in WinForms
            let cube = ModelEntity(
                mesh: .generateBox(size: 0.2),
                materials: [SimpleMaterial(color: .blue, isMetallic: true)]
            )
            content.add(cube)
        }
    }
}
```

---

## 🧪 SETTING UP FOR DEVELOPMENT

### Install Required Tools
```bash
# Install Homebrew (package manager like Chocolatey)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install helpful tools
brew install swiftlint  # Like StyleCop
brew install xcbeautify # Pretty build output
brew install gh        # GitHub CLI

# Install VS Code with Swift extension (familiar editor!)
brew install --cask visual-studio-code
code --install-extension sswg.swift-lang
```

### Configure Git for Xcode
```bash
# Set up git to ignore Xcode noise
git config --global core.excludesfile ~/.gitignore_global
echo ".DS_Store" >> ~/.gitignore_global
echo "xcuserdata/" >> ~/.gitignore_global
echo "*.xcscmblueprint" >> ~/.gitignore_global
```

---

## 🔐 ENVIRONMENT CONFIGURATION

### Create Local Config (never committed!)
```bash
# Create local configuration
cp .env.example .env.local

# Edit with your settings
nano .env.local
```

### Load Config in Swift (like ConfigurationManager)
```swift
// Config.swift
enum Config {
    static let apiKey = ProcessInfo.processInfo.environment["API_KEY"] ?? ""
    static let databasePath = ProcessInfo.processInfo.environment["DB_PATH"] ?? ""
}
```

---

## 📱 TESTING ON VISION PRO SIMULATOR

### First Run Checklist:
1. ✅ Simulator downloaded? (8GB+)
2. ✅ Xcode scheme set to visionOS?
3. ✅ Privacy permissions in Info.plist?
4. ✅ 3D assets in correct format?
5. ✅ Hand tracking enabled in simulator?

### Simulator Controls (Different from iOS!):
- `Option + Shift`: Show hands
- `Option + Mouse`: Move hands
- `Option + Scroll`: Move forward/backward
- `Control + Option`: Rotate view
- `Spacebar`: Reset view

---

## 🐛 COMMON XCODE ISSUES FOR .NET DEVS

### "No such module" Error
```bash
# Like missing assembly reference
# Fix: File > Add Package Dependencies
# Or: Clean build folder (Cmd+Shift+K)
```

### "Signing for requires a development team"
```
# Like missing strong name key
# Fix: Select your Apple ID in Signing & Capabilities
```

### "Command PhaseScriptExecution failed"
```bash
# Like MSBuild error
# Fix: Check Build Phases tab for script errors
```

---

## 📊 PROJECT HEALTH CHECKS

### Run These Before EVERY Commit:
```bash
# 1. Check for secrets
grep -r "API_KEY\|SECRET\|PASSWORD" --exclude-dir=".git" .

# 2. Check file sizes (no huge files!)
find . -type f -size +100M

# 3. Run SwiftLint
swiftlint

# 4. Build test
xcodebuild -scheme MatrixLifeLogger -configuration Debug

# 5. Check git status
git status --porcelain
```

---

## 🎯 QUICK REFERENCE CARD

### Daily Workflow Commands:
```bash
# Morning setup
cd ~/Projects/MatrixLifeLogger
git pull
open MatrixLifeLogger.xcodeproj

# Before committing
swiftlint
git add -p  # Review changes!
git commit -m "feat: descriptive message"

# End of day
git push
```

### Emergency Commands:
```bash
# Xcode acting weird?
rm -rf ~/Library/Developer/Xcode/DerivedData

# Git messed up?
git stash
git reset --hard origin/main

# Simulator frozen?
killall Simulator
```

---

## 📚 LEARNING RESOURCES

### For .NET Developers Learning Swift:
1. [Swift for C# Developers](https://www.hackingwithswift.com/articles/249/swift-for-csharp-developers)
2. [SwiftUI vs XAML](https://docs.microsoft.com/en-us/xamarin/cross-platform/guides/swift)
3. [WWDC visionOS Sessions](https://developer.apple.com/visionos/)

### Quick Conversions:
- `public class` → `public struct/class`
- `interface` → `protocol`
- `abstract class` → `protocol with default implementation`
- `async/await` → Same in Swift!
- `LINQ` → Swift functional methods (map, filter, reduce)
- `null` → `nil`
- `var?` → `Optional<Type>` or `Type?`

---

## ⚠️ FINAL WARNINGS

1. **NEVER commit .xcuserdata/** - It's like committing your .vs folder
2. **NEVER commit DerivedData/** - It's like committing bin/obj
3. **NEVER commit .DS_Store** - macOS metadata files
4. **NEVER commit real journal data** - Use mock data for testing
5. **ALWAYS use .gitignore** - See complete file below

---

## 🤝 GETTING HELP

### When Stuck, Provide These to Claude:
1. Full error message
2. Screenshot of Xcode
3. Your .NET equivalent of what you're trying to do
4. Git status output
5. Xcode version

### Magic Phrase for Claude:
"I'm a .NET developer trying to [goal] in visionOS. In Visual Studio, I would [.NET approach]. What's the Swift/Xcode equivalent?"

---

**Remember**: You're not dumb for not knowing Xcode! It's just different. Every iOS developer was confused at first too. The secret is that Xcode is basically Visual Studio with more animations and fewer features. 😄

**Last Updated**: June 2025  
**For**: Matrix Life Logger v1.0  
**By**: Claude (who also had to learn Xcode)