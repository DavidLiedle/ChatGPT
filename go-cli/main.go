package main

import (
    "bufio"
    "encoding/json"
    "errors"
    "fmt"
    "io/ioutil"
    "net/http"
    "os"
    "strings"
)

type Message struct {
    Role    string `json:"role"`
    Content string `json:"content"`
}

const historyFile = "history.json"

func loadHistory() ([]Message, error) {
    if _, err := os.Stat(historyFile); errors.Is(err, os.ErrNotExist) {
        return []Message{}, nil
    }
    b, err := ioutil.ReadFile(historyFile)
    if err != nil {
        return nil, err
    }
    if len(b) == 0 {
        return []Message{}, nil
    }
    var msgs []Message
    if err := json.Unmarshal(b, &msgs); err != nil {
        return nil, err
    }
    return msgs, nil
}

func saveHistory(msgs []Message) error {
    b, err := json.MarshalIndent(msgs, "", "  ")
    if err != nil {
        return err
    }
    return ioutil.WriteFile(historyFile, b, 0644)
}

func callOpenAI(msgs []Message, apiKey string) (string, error) {
    body, err := json.Marshal(map[string]interface{}{
        "model":    "gpt-4o",
        "messages": msgs,
    })
    if err != nil {
        return "", err
    }
    req, err := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", strings.NewReader(string(body)))
    if err != nil {
        return "", err
    }
    req.Header.Set("Authorization", "Bearer "+apiKey)
    req.Header.Set("Content-Type", "application/json")

    resp, err := http.DefaultClient.Do(req)
    if err != nil {
        return "", err
    }
    defer resp.Body.Close()
    if resp.StatusCode != http.StatusOK {
        b, _ := ioutil.ReadAll(resp.Body)
        return "", fmt.Errorf("API error: %s", string(b))
    }
    var parsed struct {
        Choices []struct {
            Message struct {
                Content string `json:"content"`
            } `json:"message"`
        } `json:"choices"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&parsed); err != nil {
        return "", err
    }
    if len(parsed.Choices) == 0 {
        return "", errors.New("no choices returned")
    }
    return parsed.Choices[0].Message.Content, nil
}

func chat(apiKey string) error {
    history, err := loadHistory()
    if err != nil {
        return err
    }
    scanner := bufio.NewScanner(os.Stdin)
    fmt.Println("Enter 'exit' to quit.")
    for {
        fmt.Print("> ")
        if !scanner.Scan() {
            break
        }
        text := strings.TrimSpace(scanner.Text())
        if text == "exit" || text == "quit" {
            break
        }
        history = append(history, Message{Role: "user", Content: text})
        reply, err := callOpenAI(history, apiKey)
        if err != nil {
            return err
        }
        fmt.Println(reply)
        history = append(history, Message{Role: "assistant", Content: reply})
        if err := saveHistory(history); err != nil {
            return err
        }
    }
    return nil
}

func printHistory() error {
    history, err := loadHistory()
    if err != nil {
        return err
    }
    for _, m := range history {
        fmt.Printf("%s: %s\n", m.Role, m.Content)
    }
    return nil
}

func clearHistory() error {
    return os.Remove(historyFile)
}

func main() {
    if len(os.Args) < 2 {
        fmt.Println("Usage: [chat|history|clear]")
        return
    }
    apiKey := os.Getenv("OPENAI_API_KEY")
    if apiKey == "" {
        fmt.Println("OPENAI_API_KEY not set")
        return
    }
    switch os.Args[1] {
    case "chat":
        if err := chat(apiKey); err != nil {
            fmt.Println("Error:", err)
        }
    case "history":
        if err := printHistory(); err != nil {
            fmt.Println("Error:", err)
        }
    case "clear":
        if err := clearHistory(); err != nil && !os.IsNotExist(err) {
            fmt.Println("Error:", err)
        }
    default:
        fmt.Println("Unknown command")
    }
}
