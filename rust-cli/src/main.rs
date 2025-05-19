use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::path::Path;

#[derive(Serialize, Deserialize, Clone)]
struct Item {
    id: u32,
    prompt: String,
    response: String,
}

const DATA_FILE: &str = "data.json";

fn load_items() -> Result<Vec<Item>, Box<dyn std::error::Error>> {
    if !Path::new(DATA_FILE).exists() {
        return Ok(Vec::new());
    }
    let data = fs::read_to_string(DATA_FILE)?;
    if data.trim().is_empty() {
        return Ok(Vec::new());
    }
    let items = serde_json::from_str(&data)?;
    Ok(items)
}

fn save_items(items: &[Item]) -> Result<(), Box<dyn std::error::Error>> {
    let data = serde_json::to_string_pretty(items)?;
    fs::write(DATA_FILE, data)?;
    Ok(())
}

fn call_openai(prompt: &str, api_key: &str) -> Result<String, Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::new();
    let body = serde_json::json!({
        "model": "gpt-4o",
        "messages": [{"role": "user", "content": prompt}],
    });
    let resp = client
        .post("https://api.openai.com/v1/chat/completions")
        .bearer_auth(api_key)
        .json(&body)
        .send()?;
    if !resp.status().is_success() {
        let text = resp.text().unwrap_or_default();
        return Err(format!("API error: {}", text).into());
    }
    #[derive(Deserialize)]
    struct ChatResponse {
        choices: Vec<Choice>,
    }
    #[derive(Deserialize)]
    struct Choice {
        message: Message,
    }
    #[derive(Deserialize)]
    struct Message {
        content: String,
    }
    let parsed: ChatResponse = resp.json()?;
    parsed
        .choices
        .get(0)
        .map(|c| c.message.content.clone())
        .ok_or_else(|| "no choices returned".into())
}

fn create_item(prompt: &str, items: &mut Vec<Item>, api_key: &str) -> Result<Item, Box<dyn std::error::Error>> {
    let response = call_openai(prompt, api_key)?;
    let id = items.last().map(|it| it.id + 1).unwrap_or(1);
    let item = Item {
        id,
        prompt: prompt.to_string(),
        response,
    };
    items.push(item.clone());
    Ok(item)
}

fn update_item(id: u32, prompt: &str, items: &mut [Item], api_key: &str) -> Result<Item, Box<dyn std::error::Error>> {
    for it in items.iter_mut() {
        if it.id == id {
            let response = call_openai(prompt, api_key)?;
            it.prompt = prompt.to_string();
            it.response = response;
            return Ok(it.clone());
        }
    }
    Err(format!("item {} not found", id).into())
}

fn delete_item(id: u32, items: &mut Vec<Item>) -> Result<(), Box<dyn std::error::Error>> {
    if let Some(pos) = items.iter().position(|it| it.id == id) {
        items.remove(pos);
        Ok(())
    } else {
        Err(format!("item {} not found", id).into())
    }
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args: Vec<String> = env::args().skip(1).collect();
    if args.is_empty() {
        println!("Usage: [create|list|update|delete] [arguments]");
        return Ok(());
    }

    let api_key = env::var("OPENAI_API_KEY").unwrap_or_default();
    if api_key.is_empty() {
        println!("OPENAI_API_KEY not set");
        return Ok(());
    }

    let cmd = args.remove(0);
    let mut items = load_items()?;

    match cmd.as_str() {
        "create" => {
            if args.is_empty() {
                println!("Usage: create <prompt>");
                return Ok(());
            }
            let prompt = &args[0];
            let item = create_item(prompt, &mut items, &api_key)?;
            save_items(&items)?;
            println!("Created item {}", item.id);
        }
        "list" => {
            for it in &items {
                println!("{}: {} -> {}", it.id, it.prompt, it.response);
            }
        }
        "update" => {
            if args.len() < 2 {
                println!("Usage: update <id> <prompt>");
                return Ok(());
            }
            let id: u32 = args[0].parse().map_err(|_| "Invalid id")?;
            let prompt = &args[1];
            let item = update_item(id, prompt, &mut items, &api_key)?;
            save_items(&items)?;
            println!("Updated item {}", item.id);
        }
        "delete" => {
            if args.is_empty() {
                println!("Usage: delete <id>");
                return Ok(());
            }
            let id: u32 = args[0].parse().map_err(|_| "Invalid id")?;
            delete_item(id, &mut items)?;
            save_items(&items)?;
            println!("Deleted item {}", id);
        }
        _ => {
            println!("Unknown command");
        }
    }

    Ok(())
}
