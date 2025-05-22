package me.davidcanhelp.chatgpt;

import org.junit.Test;
import org.junit.Assert;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

public class ChatWindowTopComponentTest {
    @Test
    public void testReadApiKeyFromFileMissing() throws Exception {
        ChatWindowTopComponent comp = new ChatWindowTopComponent();
        String orig = System.getProperty("user.home");
        Path tmp = Files.createTempDirectory("testhome");
        System.setProperty("user.home", tmp.toString());
        try {
            Method m = ChatWindowTopComponent.class.getDeclaredMethod("readApiKeyFromFile");
            m.setAccessible(true);
            Assert.assertThrows(IOException.class, () -> {
                try {
                    m.invoke(comp);
                } catch (InvocationTargetException e) {
                    if (e.getCause() instanceof IOException) {
                        throw (IOException) e.getCause();
                    }
                    throw new RuntimeException(e.getCause());
                }
            });
        } finally {
            System.setProperty("user.home", orig);
        }
    }

    @Test
    public void testReadApiKeyFromFileSuccess() throws Exception {
        ChatWindowTopComponent comp = new ChatWindowTopComponent();
        String orig = System.getProperty("user.home");
        Path tmp = Files.createTempDirectory("home");
        java.nio.file.Path conf = tmp.resolve(".config/chatgpt");
        Files.createDirectories(conf);
        Files.writeString(conf.resolve("apikey.txt"), "secret");
        System.setProperty("user.home", tmp.toString());
        try {
            Method m = ChatWindowTopComponent.class.getDeclaredMethod("readApiKeyFromFile");
            m.setAccessible(true);
            String key = (String) m.invoke(comp);
            Assert.assertEquals("secret", key);
        } finally {
            System.setProperty("user.home", orig);
        }
    }

    @Test
    public void testWriteAndReadProperties() throws Exception {
        ChatWindowTopComponent comp1 = new ChatWindowTopComponent();
        java.lang.reflect.Field f = ChatWindowTopComponent.class.getDeclaredField("currentModel");
        f.setAccessible(true);
        f.set(comp1, "gpt-3.5-turbo");
        java.util.Properties p = new java.util.Properties();
        comp1.writeProperties(p);

        ChatWindowTopComponent comp2 = new ChatWindowTopComponent();
        comp2.readProperties(p);
        f.setAccessible(true);
        String model = (String) f.get(comp2);
        Assert.assertEquals("gpt-3.5-turbo", model);
    }
}
