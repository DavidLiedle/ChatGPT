# clojure-cli

A simple command line tool written in Clojure for chatting with ChatGPT. It mirrors the other CLI implementations and stores your conversation history locally. Set `OPENAI_API_KEY` before running.

## Usage

```bash
# start an interactive chat
clojure -M -m chat-cli.core chat

# show saved history
clojure -M -m chat-cli.core history

# clear saved history
clojure -M -m chat-cli.core clear
```
