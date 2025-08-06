# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter application for tracking escape room experiences. The app allows users to create diary entries for escape rooms they've visited, including details about the cafe, theme, friends who participated, ratings, and game results.

## Development Commands

### Flutter Commands
- `flutter run` - Run the application in development mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter test` - Run tests
- `flutter analyze` - Run static analysis
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Upgrade dependencies

### Platform-Specific Commands
- `flutter run -d android` - Run on Android device/emulator
- `flutter run -d ios` - Run on iOS device/simulator
- `flutter run -d web` - Run on web browser
- `flutter run -d macos` - Run on macOS
- `flutter run -d linux` - Run on Linux
- `flutter run -d windows` - Run on Windows

## Architecture

### Core Structure
The app follows a simple Flutter architecture pattern:

- **main.dart**: Entry point with global state management for diary entries
- **models/**: Data models for the application
  - `diary.dart`: DiaryEntry model representing escape room experiences
  - `escape_cafe.dart`: EscapeCafe and EscapeTheme models
  - `user.dart`: User and Friend models
- **screens/**: UI screens for different app functions
  - `diary_list_screen.dart`: Main list view of diary entries
  - `diary_detail_screen.dart`: Detailed view of individual entries
  - `write_diary_screen.dart`: Form for creating new entries
  - `edit_diary_screen.dart`: Form for editing existing entries

### State Management
- Uses StatefulWidget at the app level (MyApp) to manage the global list of diary entries
- Callback functions (onAdd, onUpdate) are passed down to child widgets for state updates
- No external state management library is used

### Data Flow
- DiaryEntry objects are created with mock data structure including cafe, theme, friends, ratings, and game results
- Navigation between screens uses Navigator.push with MaterialPageRoute
- Data is passed between screens through constructor parameters and return values

### Key Models Relationships
- DiaryEntry contains an EscapeTheme
- EscapeTheme belongs to an EscapeCafe
- DiaryEntry can have multiple Friend objects
- Friend objects contain User information

## Development Notes

### Language and Framework
- Flutter SDK version: ^3.7.2
- Uses Material 3 design system
- Korean language used for UI strings ("탈출일지" means "Escape Diary")

### Testing
- Test files are located in the `test/` directory
- Uses flutter_test framework
- Run tests with `flutter test`

### Code Style
- Uses flutter_lints for code analysis
- Analysis rules defined in analysis_options.yaml
- Follows standard Flutter/Dart conventions

# Do Not Section
- 주석을 칠땐, 최상단 import 에는 설명용 주석을 할 필요 없습니다. 
- 