package main

import (
    "os"
    "reflect"
    "testing"
)

func TestSaveAndLoadItems(t *testing.T) {
    dir := t.TempDir()
    prev, _ := os.Getwd()
    os.Chdir(dir)
    defer os.Chdir(prev)

    items := []Item{{ID: 1, Prompt: "p", Response: "r"}}
    if err := saveItems(items); err != nil {
        t.Fatal(err)
    }
    loaded, err := loadItems()
    if err != nil {
        t.Fatal(err)
    }
    if !reflect.DeepEqual(items, loaded) {
        t.Errorf("expected %v got %v", items, loaded)
    }
}

func TestDeleteItem(t *testing.T) {
    items := []Item{{ID: 1, Prompt: "a", Response: "b"}, {ID: 2, Prompt: "c", Response: "d"}}
    out, err := deleteItem(1, items)
    if err != nil {
        t.Fatal(err)
    }
    if len(out) != 1 || out[0].ID != 2 {
        t.Fatalf("unexpected result: %v", out)
    }
    if _, err := deleteItem(3, items); err == nil {
        t.Fatal("expected error")
    }
}
