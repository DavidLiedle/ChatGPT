# ChatGPT Solutions

This repository contains multiple implementations that interact with the OpenAI API. Each implementation lives in its own folder.

- `NetBeans/` – NetBeans plugin (v2.0) providing a GUI for ChatGPT.
- `go-cli/` – A command line interface written in Go.
- `flutter-gui/` – A minimal Flutter application providing a GUI interface.
- `dart-cli/` – A command line interface written in Dart.
- `rust-cli/` – A command line interface written in Rust.

All CLI implementations share the same workflow: start an interactive `chat` session, inspect `history`, or `clear` the stored conversation. Each subfolder may provide additional documentation.

## Testing

Each subproject provides unit tests where possible:

- **go-cli**: run `go test ./...`
- **rust-cli**: run `cargo test`
- **dart-cli** and **flutter-gui**: run `dart test` or `flutter test`
- **NetBeans**: run `mvn test`

Some environments may need additional SDKs or build tools installed before tests can run.
