package main

import (
    "os"
    "reflect"
    "testing"
)

func TestSaveAndLoadHistory(t *testing.T) {
    dir := t.TempDir()
    prev, _ := os.Getwd()
    os.Chdir(dir)
    defer os.Chdir(prev)

    msgs := []Message{{Role: "user", Content: "hello"}}
    if err := saveHistory(msgs); err != nil {
        t.Fatal(err)
    }
    loaded, err := loadHistory()
    if err != nil {
        t.Fatal(err)
    }
    if !reflect.DeepEqual(msgs, loaded) {
        t.Errorf("expected %v got %v", msgs, loaded)
    }
}

func TestClearHistory(t *testing.T) {
    dir := t.TempDir()
    prev, _ := os.Getwd()
    os.Chdir(dir)
    defer os.Chdir(prev)

    msgs := []Message{{Role: "user", Content: "bye"}}
    if err := saveHistory(msgs); err != nil {
        t.Fatal(err)
    }
    if err := clearHistory(); err != nil {
        t.Fatal(err)
    }
    if _, err := os.Stat(historyFile); !os.IsNotExist(err) {
        t.Fatalf("history file should be removed")
    }
}

func TestLoadHistoryMissingAndEmpty(t *testing.T) {
    dir := t.TempDir()
    prev, _ := os.Getwd()
    os.Chdir(dir)
    defer os.Chdir(prev)

    // missing file
    msgs, err := loadHistory()
    if err != nil {
        t.Fatal(err)
    }
    if len(msgs) != 0 {
        t.Fatalf("expected empty slice, got %v", msgs)
    }

    // empty file
    if err := os.WriteFile(historyFile, []byte(""), 0644); err != nil {
        t.Fatal(err)
    }
    msgs, err = loadHistory()
    if err != nil {
        t.Fatal(err)
    }
    if len(msgs) != 0 {
        t.Fatalf("expected empty slice for empty file, got %v", msgs)
    }
}
