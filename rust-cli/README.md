# rust-cli

A command line application written in Rust that lets you chat with ChatGPT from your terminal. It follows the same workflow as the other CLI implementations and stores your conversation history locally. Ensure `OPENAI_API_KEY` is set before running.

## Usage

```bash
# interactive conversation
cargo run -- chat

# show previous history
cargo run -- history

# clear saved history
cargo run -- clear
```
