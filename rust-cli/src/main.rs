use std::fs;
use std::io::{self, Write};
use std::path::Path;
use std::process::Command;

struct Message {
    role: String,
    content: String,
}

const HISTORY_FILE: &str = "history.txt";

fn load_history() -> io::Result<Vec<Message>> {
    if !Path::new(HISTORY_FILE).exists() {
        return Ok(Vec::new());
    }
    let data = fs::read_to_string(HISTORY_FILE)?;
    let mut msgs = Vec::new();
    for line in data.lines() {
        if let Some((role, content)) = line.split_once(':') {
            msgs.push(Message { role: role.into(), content: content.into() });
        }
    }
    Ok(msgs)
}

fn save_history(msgs: &[Message]) -> io::Result<()> {
    let mut data = String::new();
    for m in msgs {
        data.push_str(&format!("{}:{}\n", m.role, m.content));
    }
    fs::write(HISTORY_FILE, data)
}

fn escape(s: &str) -> String {
    s.replace('"', "\\\"")
}

fn call_openai(msgs: &[Message], api_key: &str) -> Result<String, Box<dyn std::error::Error>> {
    let messages_json = msgs
        .iter()
        .map(|m| format!("{{\"role\":\"{}\",\"content\":\"{}\"}}", m.role, escape(&m.content)))
        .collect::<Vec<_>>()
        .join(",");
    let body = format!("{{\"model\":\"gpt-4o\",\"messages\":[{}]}}", messages_json);
    let cmd = format!(
        "curl -s -H 'Authorization: Bearer {api_key}' -H 'Content-Type: application/json' -d '{body}' https://api.openai.com/v1/chat/completions | jq -r '.choices[0].message.content'"
    );
    let out = Command::new("sh").arg("-c").arg(cmd).output()?;
    if !out.status.success() {
        return Err(format!("curl failed: {:?}", out.status).into());
    }
    Ok(String::from_utf8_lossy(&out.stdout).trim().to_string())
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

fn print_history() -> io::Result<()> {
    for m in load_history()? {
        println!("{}: {}", m.role, m.content);
    }
    Ok(())
}

fn clear_history() -> io::Result<()> {
    if Path::new(HISTORY_FILE).exists() {
        fs::remove_file(HISTORY_FILE)?;
    }
    Ok(())
}

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut args: Vec<String> = std::env::args().skip(1).collect();
    if args.is_empty() {
        println!("Usage: [chat|history|clear]");
        return Ok(());
    }
    let api_key = std::env::var("OPENAI_API_KEY").unwrap_or_default();
    if api_key.is_empty() {
        println!("OPENAI_API_KEY not set");
        return Ok(());
    }
    match args.remove(0).as_str() {
        "chat" => chat(&api_key)?,
        "history" => print_history()?,
        "clear" => clear_history()?,
        _ => println!("Unknown command"),
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    #[test]
    fn simple_add() {
        assert_eq!(1 + 1, 2);
    }
}
