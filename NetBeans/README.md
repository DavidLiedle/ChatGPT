# ChatGPT NetBeans Plugin 2.0

This module provides a simple chat interface to the OpenAI API directly inside NetBeans.

## Features

* Conversation history with ChatGPT persisted for the session.
* Select the model (gpt-4o or gpt-3.5-turbo) from a dropdown.
* Clear the current conversation.
* API key loaded from `~/.config/chatgpt/apikey.txt`.

## Building

Run `mvn package` inside the `NetBeans` folder to build the plugin NBMs.

## Installing

Use the NetBeans Plugin Manager to install the generated `.nbm` file.
