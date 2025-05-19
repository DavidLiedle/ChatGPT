# dart-cli

A Dart command line application for chatting with ChatGPT. It shares the same workflow as the other CLI tools and stores conversation history locally. Set `OPENAI_API_KEY` in your environment before running.

## Usage

```bash
# start an interactive session
dart run bin/dart_cli.dart chat

# view saved history
dart run bin/dart_cli.dart history

# remove saved history
dart run bin/dart_cli.dart clear
```
