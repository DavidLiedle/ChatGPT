# go-cli

A command line tool written in Go for chatting with ChatGPT. The tool provides an interactive conversation mode and stores your chat history locally. Set the `OPENAI_API_KEY` environment variable with your API key before running.

## Usage

```bash
# start an interactive conversation
go run main.go chat

# print previous conversation history
go run main.go history

# clear saved history
go run main.go clear
```
