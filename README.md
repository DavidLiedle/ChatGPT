# ChatGPT Solutions

This repository contains multiple implementations that interact with the OpenAI API. Each implementation lives in its own folder.

- `NetBeans/` – NetBeans plugin (v2.0) providing a GUI for ChatGPT.
- `go-cli/` – A command line interface written in Go.
- `flutter-gui/` – A minimal Flutter application providing a GUI interface.
- `dart-cli/` – A command line interface written in Dart.
- `rust-cli/` – A command line interface written in Rust.
- `perl-cli/` – A command line interface written in Perl.
- `clojure-cli/` – A command line interface written in Clojure.

All CLI implementations share the same workflow: start an interactive `chat` session, inspect `history`, or `clear` the stored conversation. Each subfolder may provide additional documentation.

## Requirements

All implementations require the `OPENAI_API_KEY` environment variable to be set with a valid OpenAI API key.

### Platform-Specific Requirements

- **perl-cli**: Requires `Net::SSLeay` module for HTTPS support. Install with `cpan -T Net::SSLeay` if not already present.

## Testing

Each subproject provides unit tests where possible:

- **go-cli**: run `go test ./...`
- **rust-cli**: run `cargo test`
- **dart-cli** and **flutter-gui**: run `dart test` or `flutter test`
- **NetBeans**: run `mvn test`
- **perl-cli**: run `prove -I . t`
- **clojure-cli**: run `clojure -X:test`

Some environments may need additional SDKs or build tools installed before tests can run.
