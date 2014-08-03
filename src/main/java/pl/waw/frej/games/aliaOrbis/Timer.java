package pl.waw.frej.games.aliaOrbis;

import org.lwjgl.Sys;

/**
 * Created by adam on 03.08.14.
 */
public class Timer {
    private long lastFrame;
    private long lastFPS;
    private int framesCount;
    private int currentFps;

    public void init() {
        getDelta();
        lastFPS = getTime();
    }

    private long getTime() {
        return (Sys.getTime() * 1000) / Sys.getTimerResolution();
    }

    public int getDelta() {
        long time = getTime();
        int delta = (int) (time - lastFrame);
        lastFrame = time;

        return delta;
    }

    public long getTimePassed(){
        return getTime() - lastFPS;
    }

    public int getCurrentFps() {
        return currentFps;
    }

    public void update() {
        if (getTime() - lastFPS > 1000) {
            currentFps = framesCount;
            framesCount = 0;
            lastFPS += 1000;
        }
        framesCount++;
    }
}
