# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-language ChatGPT client collection demonstrating OpenAI API integration across 7 different programming languages and frameworks. Each implementation provides consistent functionality (chat, history, clear commands) while following language-specific conventions.

## Development Commands

### Building Projects

```bash
# NetBeans Plugin (Java)
cd NetBeans && mvn package

# Go CLI
cd go-cli && go build

# Rust CLI
cd rust-cli && cargo build

# Dart CLI
cd dart-cli && dart compile exe bin/dart_cli.dart

# Flutter GUI
cd flutter-gui && flutter build

# Clojure CLI
cd clojure-cli && clojure -M -m chat-cli.core

# Perl CLI (no build needed)
cd perl-cli && perl perl_cli.pl
```

### Running Tests

```bash
# NetBeans
cd NetBeans && mvn test

# Go
cd go-cli && go test ./...

# Rust
cd rust-cli && cargo test

# Dart
cd dart-cli && dart test

# Flutter
cd flutter-gui && flutter test

# Clojure
cd clojure-cli && clojure -X:test

# Perl
cd perl-cli && prove -I . t
```

### Running Single Tests

```bash
# Go
cd go-cli && go test -run TestFunctionName

# Rust
cd rust-cli && cargo test test_name

# Java/Maven
cd NetBeans && mvn test -Dtest=ClassName#methodName

# Dart
cd dart-cli && dart test test/specific_test.dart

# Flutter
cd flutter-gui && flutter test test/specific_test.dart
```

## Architecture

### Repository Structure
- **Monorepo pattern**: Each language implementation in its own directory
- **Consistent API**: All implementations use OpenAI's chat completions API with GPT-4o model
- **Local storage**: Conversation history stored locally (JSON or text files)
- **Environment configuration**: API key from `OPENAI_API_KEY` environment variable

### Key Implementation Patterns
1. **CLI Commands**: All CLI tools implement `chat`, `history`, and `clear` commands
2. **Error Handling**: Each implementation handles API errors and missing API keys gracefully
3. **Minimal Dependencies**: Implementations favor minimal external dependencies (notably Rust uses curl via shell)
4. **Testing**: Each implementation includes unit tests for core functionality

### CI/CD Pipeline
GitHub Actions workflow (`.github/workflows/ci.yml`) runs tests for:
- Go (using version from go.mod)
- Rust (stable toolchain)
- Dart (SDK >=2.17.0)
- Flutter (stable channel)
- Java (Temurin JDK 17)

Note: Clojure and Perl are not included in CI pipeline.

## Language-Specific Notes

### NetBeans Plugin
- Version 2.0, uses NetBeans API RELEASE220
- Built as NBM plugin file
- Uses OkHttp for HTTP requests
- Java 8 compatible bytecode, built with JDK 17

### Go CLI
- Go 1.23.8
- Standard library only, no external dependencies
- Structured with main.go entry point

### Rust CLI
- Edition 2021
- Zero external crates - uses system curl command
- Minimal implementation focused on simplicity

### Dart/Flutter
- Dart SDK >=2.17.0
- Flutter uses stable channel
- HTTP package for API calls
- Path provider for local storage in Flutter

### Clojure CLI
- Uses deps.edn for dependencies
- clj-http for HTTP, cheshire for JSON
- Functional programming approach

### Perl CLI
- Standard Perl modules only
- Command-line focused implementation