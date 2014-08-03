package pl.waw.frej.games.aliaOrbis;

import com.typesafe.config.Config;
import com.typesafe.config.ConfigFactory;
import org.lwjgl.LWJGLException;
import org.lwjgl.Sys;
import org.lwjgl.opengl.Display;
import org.lwjgl.opengl.DisplayMode;
import org.lwjgl.opengl.GL11;

/**
 * Created by adam on 03.08.14.
 */
public class WindowUtils {
    public static void renderTriangle() {
        GL11.glClear(GL11.GL_COLOR_BUFFER_BIT | GL11.GL_STENCIL_BUFFER_BIT);


        GL11.glRotatef(0.6f, 0, 0, 1);
        GL11.glBegin(GL11.GL_TRIANGLES);
        GL11.glVertex3f(-0.5f, -0.5f, 0);
        GL11.glVertex3f(0.5f, -0.5f, 0);
        GL11.glVertex3f(0, 0.5f, 0);

        GL11.glEnd();
    }

    public static void initializeDisplay(int targetWidth, int targetHeight, boolean fullscreen) {
        try {
            DisplayMode chosenMode = new DisplayMode(targetWidth, targetHeight);

            Display.setDisplayMode(chosenMode);
            Display.setTitle("Alia Orbis");
            Display.setFullscreen(fullscreen);
            Display.create();
        } catch (LWJGLException e) {
            Sys.alert("Error", "Unable to create display.");
            System.exit(0);
        }

        GL11.glClearColor(0, 0, 0, 0);
    }

    public static Config getConfig() {
        return ConfigFactory.load("settings.conf");
    }
}
