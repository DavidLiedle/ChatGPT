use serde::{Deserialize, Serialize};
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::Path;

#[derive(Serialize, Deserialize, Clone)]
struct Message {
    role: String,
    content: String,
}

const HISTORY_FILE: &str = "history.json";

fn load_history() -> Result<Vec<Message>, Box<dyn std::error::Error>> {
    if !Path::new(HISTORY_FILE).exists() {
        return Ok(Vec::new());
    }
    let data = fs::read_to_string(HISTORY_FILE)?;
    if data.trim().is_empty() {
        return Ok(Vec::new());
    }
    let msgs = serde_json::from_str(&data)?;
    Ok(msgs)
}

fn save_history(msgs: &[Message]) -> Result<(), Box<dyn std::error::Error>> {
    let data = serde_json::to_string_pretty(msgs)?;
    fs::write(HISTORY_FILE, data)?;
    Ok(())
}

fn call_openai(msgs: &[Message], api_key: &str) -> Result<String, Box<dyn std::error::Error>> {
    let client = reqwest::blocking::Client::new();
    let body = serde_json::json!({
        "model": "gpt-4o",
        "messages": msgs,
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
        message: MessageInner,
    }
    #[derive(Deserialize)]
    struct MessageInner {
        content: String,
    }
    let parsed: ChatResponse = resp.json()?;
    parsed
        .choices
        .get(0)
        .map(|c| c.message.content.clone())
        .ok_or_else(|| "no choices returned".into())
}

fn chat(api_key: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut history = load_history()?;
    let stdin = io::stdin();
    let mut input = String::new();
    println!("Enter 'exit' to quit.");
    loop {
        input.clear();
        print!("> ");
        io::stdout().flush()?;
        if stdin.read_line(&mut input)? == 0 {
            break;
        }
        let text = input.trim();
        if text == "exit" || text == "quit" {
            break;
        }
        history.push(Message { role: "user".into(), content: text.into() });
        let reply = call_openai(&history, api_key)?;
        println!("{}", reply);
        history.push(Message { role: "assistant".into(), content: reply });
        save_history(&history)?;
    }
    Ok(())
}

fn print_history() -> Result<(), Box<dyn std::error::Error>> {
    let history = load_history()?;
    for m in history {
        println!("{}: {}", m.role, m.content);
    }
    Ok(())
}

fn clear_history() -> Result<(), Box<dyn std::error::Error>> {
    if Path::new(HISTORY_FILE).exists() {
        fs::remove_file(HISTORY_FILE)?;
    }
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args: Vec<String> = env::args().skip(1).collect();
    if args.is_empty() {
        println!("Usage: [chat|history|clear]");
        return Ok(());
    }
    let api_key = env::var("OPENAI_API_KEY").unwrap_or_default();
    if api_key.is_empty() {
        println!("OPENAI_API_KEY not set");
        return Ok(());
    }
    let cmd = args.remove(0);
    match cmd.as_str() {
        "chat" => chat(&api_key)?,
        "history" => print_history()?,
        "clear" => clear_history()?,
        _ => println!("Unknown command"),
    }
    Ok(())
}
