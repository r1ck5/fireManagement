# AGENTS.md - Flutter Fire Management App Guidelines

This document provides essential information for agentic coding agents working on the fireManagement Flutter project.

## Project Overview

- **Type**: Flutter mobile application (iOS/Android)
- **Language**: Dart
- **Flutter Version**: 3.3.0
- **Purpose**: Demonstrates flutter_map_arcgis plugin usage for fire management mapping

## Build, Test & Lint Commands

### Getting Started
```bash
# Install dependencies
flutter pub get

# Generate code (JSON serialization)
flutter pub run build_runner build

# Watch mode for code generation
flutter pub run build_runner watch
```

### Running the App
```bash
# Run on connected device/emulator
flutter run

# Run with specific configuration
flutter run --release
```

### Testing
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_name.dart

# Run tests with verbose output
flutter test --verbose

# Run tests matching a pattern
flutter test --name "pattern_name"
```

### Code Analysis & Linting
```bash
# Analyze code
dart analyze

# Fix analyzer issues
dart fix --apply

# Format code (use as style guide reference)
dart format lib/
```

## Code Style Guidelines

### Naming Conventions
- **Classes**: PascalCase (e.g., `AirMapController`, `MainScreen`)
- **Variables & Functions**: camelCase (e.g., `countryId`, `fromJson()`)
- **Constants**: camelCase with `const` keyword
- **Files**: snake_case (e.g., `map_ctrl.dart`, `fire_management_api.dart`)
- **Widgets**: PascalCase ending in `Screen`, `Widget`, etc. (e.g., `MainScreen`, `MapWidget`)
- **Controllers**: PascalCase ending in `Controller` (e.g., `AirMapController`, `MapCtrl`)

### Imports
- Order: dart packages → flutter packages → app packages
- Use relative imports within the app package
- Example:
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_map/flutter_map.dart';
  import 'package:flutter_map_arcgis_example/Routes.dart';
  ```

### Formatting
- Use 2-space indentation (Dart standard)
- Max line length: 80 characters (Dart conventions)
- Use `final` for variables that don't change
- One blank line between method/class definitions

### Types & Null Safety
- Use `required` keyword for mandatory parameters
- Prefer explicit types over `var`
- Use null coalescing operator (`??`) with safe defaults
- Example:
  ```dart
  latitude: num.tryParse(json['latitude'])?.toDouble() ?? 0,
  ```

### JSON Serialization
- Use `@JsonSerializable()` decorator for model classes
- Use `@JsonKey(name: "...")` for JSON field mapping
- Generate `.g.dart` files with build_runner
- Implement both `fromJson()` factory and `toJson()` method
- Include `.fromMap()` factory for custom parsing logic

### Error Handling
- Use try-catch for async operations (HTTP requests, file I/O)
- Provide meaningful error messages
- Log errors appropriately
- Handle parsing errors gracefully with defaults:
  ```dart
  int.tryParse(value) ?? 0
  num.tryParse(value)?.toDouble() ?? 0
  ```

### State Management
- Use GetX for reactive state (`.obs`, `GetxController`)
- Controllers should extend `GetxController`
- Use `GetMaterialApp` for routing and dependency injection
- Create bindings in `MainBinding` or route-specific bindings

### Widget Structure
- Stateless vs Stateful: Use Stateless when possible
- Extract large widgets into separate files
- Name widget files descriptively (e.g., `main_screen.dart`)
- Use const constructors where applicable

### API & HTTP
- Use Dio or http package for API calls
- Keep API endpoints in separate files (`api/`)
- Model all API responses as Dart classes
- Handle network errors appropriately

## Project Structure

```
lib/
├── api/                  # API clients and endpoints
├── controllers/          # GetX controllers for state
├── models/              # Data models (with .g.dart generated files)
├── screens/             # Full-screen widgets
├── widgets/             # Reusable widget components
├── utils/               # Helper functions and utilities
├── Routes.dart          # Route definitions
├── mainBindings.dart    # Dependency injection setup
└── main.dart            # App entry point
```

## Key Dependencies

- **flutter_map**: Map widget
- **flutter_map_arcgis**: ArcGIS layers support
- **get**: State management and routing
- **dio/http**: HTTP client
- **json_serializable**: JSON serialization code generation
- **latlong2**: Geographic coordinates
- **flutter_map_marker_cluster**: Marker clustering
- **rxdart**: Reactive extensions

## Pre-commit Checklist

Before committing code:
- [ ] Run `dart analyze` - no warnings or errors
- [ ] Run `flutter test` - all tests pass
- [ ] Verify `build_runner build` succeeds for JSON models
- [ ] Follow naming conventions consistently
- [ ] No unused imports or variables
- [ ] Error handling implemented
- [ ] Types explicitly declared

## Communication Guidelines for Agents

Keep summaries **lean, objective, and factual**:
- No success statistics, percentage counts, or verbose status descriptions
- Avoid repetitive summaries listing what was already done
- Skip unnecessary details about tool outputs or intermediate steps
- Focus only on: what changed, why it matters, what needs attention next
- Use concise bullet points (max 2-3 lines per item)
- No excessive line counts or long text blocks unless essential for clarity
- Omit verbose "done/completed/finished" statements—show action over narrative
