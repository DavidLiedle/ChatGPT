# rust-cli

A tiny Rust command line example that chats with the OpenAI API using `curl`.
The implementation avoids external crates so it builds offline. History is stored
in `history.txt` in the current directory.

## Usage

```bash
# interactive conversation
cargo run -- chat

# show previous history
cargo run -- history

# clear saved history
cargo run -- clear
```
