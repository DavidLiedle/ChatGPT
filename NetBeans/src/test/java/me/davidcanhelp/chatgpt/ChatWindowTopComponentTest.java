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
}
