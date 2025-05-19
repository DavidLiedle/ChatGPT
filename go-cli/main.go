package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
)

type Item struct {
	ID       int    `json:"id"`
	Prompt   string `json:"prompt"`
	Response string `json:"response"`
}

const dataFile = "data.json"

func loadItems() ([]Item, error) {
	if _, err := os.Stat(dataFile); errors.Is(err, os.ErrNotExist) {
		return []Item{}, nil
	}
	b, err := ioutil.ReadFile(dataFile)
	if err != nil {
		return nil, err
	}
	var items []Item
	if len(b) == 0 {
		return []Item{}, nil
	}
	if err := json.Unmarshal(b, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func saveItems(items []Item) error {
	b, err := json.MarshalIndent(items, "", "  ")
	if err != nil {
		return err
	}
	return ioutil.WriteFile(dataFile, b, 0644)
}

func callOpenAI(prompt, apiKey string) (string, error) {
	reqBody := fmt.Sprintf(`{"model":"gpt-4o","messages":[{"role":"user","content":"%s"}]}`, prompt)
	req, err := http.NewRequest("POST", "https://api.openai.com/v1/chat/completions", strings.NewReader(reqBody))
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

func createItem(prompt string, items []Item, apiKey string) ([]Item, Item, error) {
	response, err := callOpenAI(prompt, apiKey)
	if err != nil {
		return items, Item{}, err
	}
	id := 1
	if len(items) > 0 {
		id = items[len(items)-1].ID + 1
	}
	item := Item{ID: id, Prompt: prompt, Response: response}
	items = append(items, item)
	return items, item, nil
}

func updateItem(id int, prompt string, items []Item, apiKey string) ([]Item, Item, error) {
	for i, it := range items {
		if it.ID == id {
			response, err := callOpenAI(prompt, apiKey)
			if err != nil {
				return items, Item{}, err
			}
			items[i].Prompt = prompt
			items[i].Response = response
			return items, items[i], nil
		}
	}
	return items, Item{}, fmt.Errorf("item %d not found", id)
}

func deleteItem(id int, items []Item) ([]Item, error) {
	for i, it := range items {
		if it.ID == id {
			return append(items[:i], items[i+1:]...), nil
		}
	}
	return items, fmt.Errorf("item %d not found", id)
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: [create|list|update|delete] [arguments]")
		return
	}
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		fmt.Println("OPENAI_API_KEY not set")
		return
	}
	cmd := os.Args[1]

	items, err := loadItems()
	if err != nil {
		fmt.Println("Error loading items:", err)
		return
	}

	switch cmd {
	case "create":
		if len(os.Args) < 3 {
			fmt.Println("Usage: create <prompt>")
			return
		}
		prompt := os.Args[2]
		items, item, err := createItem(prompt, items, apiKey)
		if err != nil {
			fmt.Println("Error creating item:", err)
			return
		}
		if err := saveItems(items); err != nil {
			fmt.Println("Error saving items:", err)
			return
		}
		fmt.Printf("Created item %d\n", item.ID)
	case "list":
		for _, it := range items {
			fmt.Printf("%d: %s -> %s\n", it.ID, it.Prompt, it.Response)
		}
	case "update":
		if len(os.Args) < 4 {
			fmt.Println("Usage: update <id> <prompt>")
			return
		}
		id, err := strconv.Atoi(os.Args[2])
		if err != nil {
			fmt.Println("Invalid id")
			return
		}
		prompt := os.Args[3]
		items, item, err := updateItem(id, prompt, items, apiKey)
		if err != nil {
			fmt.Println("Error updating item:", err)
			return
		}
		if err := saveItems(items); err != nil {
			fmt.Println("Error saving items:", err)
			return
		}
		fmt.Printf("Updated item %d\n", item.ID)
	case "delete":
		if len(os.Args) < 3 {
			fmt.Println("Usage: delete <id>")
			return
		}
		id, err := strconv.Atoi(os.Args[2])
		if err != nil {
			fmt.Println("Invalid id")
			return
		}
		items, err = deleteItem(id, items)
		if err != nil {
			fmt.Println("Error deleting item:", err)
			return
		}
		if err := saveItems(items); err != nil {
			fmt.Println("Error saving items:", err)
			return
		}
		fmt.Printf("Deleted item %d\n", id)
	default:
		fmt.Println("Unknown command")
	}
}
