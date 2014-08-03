package pl.waw.frej.games.aliaOrbis;

import org.lwjgl.opengl.Display;

import static pl.waw.frej.games.aliaOrbis.WindowUtils.initializeDisplay;
import static pl.waw.frej.games.aliaOrbis.WindowUtils.renderTriangle;

/**
 * Created by adam on 03.08.14.
 */
public class MainWindow {
    private static final int TARGET_WIDTH = 640;
    private static final int TARGET_HEIGHT = 480;
    private static final int FRAME_RATE = 120;
    private static Timer timer = new Timer();

    public static void main(String[] args) {
        initializeDisplay(TARGET_WIDTH, TARGET_HEIGHT);
        boolean gameRunning = true;

        timer.init();
        while (gameRunning) {
            renderTriangle();


            if(timer.getTimePassed()>1000) {
                Display.setTitle("FPS: " + timer.getCurrentFps());
            }
            timer.update();

            Display.update();
            Display.sync(FRAME_RATE);

            if (Display.isCloseRequested()) {
                gameRunning = false;
                Display.destroy();
                System.exit(0);
            }
        }
    }
}
