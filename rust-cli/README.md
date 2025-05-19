# rust-cli

A simple command line tool written in Rust that interacts with the OpenAI API. The tool supports creating, listing, updating and deleting stored prompts and responses. The API key must be provided in the `OPENAI_API_KEY` environment variable.

## Usage

```
cargo run -- create "your prompt"
cargo run -- list
cargo run -- update <id> "new prompt"
cargo run -- delete <id>
```

Each command updates a local `data.json` file used for storage.

