# dart-cli

This directory contains a Dart command line application that interacts with the OpenAI API. It mirrors the features of the Go CLI by allowing you to create, list, update, and delete stored prompts and responses.

## Usage

```bash
dart run bin/dart_cli.dart --create "your prompt"
dart run bin/dart_cli.dart --list
dart run bin/dart_cli.dart --update 1 "new prompt"
dart run bin/dart_cli.dart --delete 1
```

An API key must be provided through the `OPENAI_API_KEY` environment variable. All items are stored in a local `data.json` file.
