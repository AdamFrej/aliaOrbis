package pl.waw.frej.games.aliaOrbis;

import org.lwjgl.opengl.Display;
import pl.waw.frej.games.aliaOrbis.model.World;
import pl.waw.frej.games.aliaOrbis.model.WorldFactory;

import static pl.waw.frej.games.aliaOrbis.WindowUtils.getConfig;
import static pl.waw.frej.games.aliaOrbis.WindowUtils.initializeDisplay;
import static pl.waw.frej.games.aliaOrbis.WindowUtils.renderTriangle;

/**
 * Created by adam on 03.08.14.
 */
public class MainWindow {

    private static Timer timer = new Timer();

    public static void main(String[] args) {
        initializeDisplay(getConfig().getInt("width"), getConfig().getInt("height"),getConfig().getBoolean("fullscreen"));
        boolean gameRunning = true;

        timer.init();
        World world = WorldFactory.loadWorld();
        while (gameRunning) {
            renderTriangle();


            if(timer.getTimePassed()>1000) {
                Display.setTitle("FPS: " + timer.getCurrentFps());
            }
            timer.update();

            Display.update();
            Display.sync(getConfig().getInt("maxFPS"));

            if (Display.isCloseRequested()) {
                gameRunning = false;
                Display.destroy();
                System.exit(0);
            }
        }
    }
}
