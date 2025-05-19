# go-cli

A simple command line tool that interacts with the OpenAI API. The tool supports
creating, listing, updating and deleting stored prompts and responses. The API
key must be provided in the `OPENAI_API_KEY` environment variable.

## Usage

```
go run main.go create "your prompt"
go run main.go list
go run main.go update <id> "new prompt"
go run main.go delete <id>
```

Each command updates a local `data.json` file used for storage.

