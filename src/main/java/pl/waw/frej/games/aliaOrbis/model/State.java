package pl.waw.frej.games.aliaOrbis.model;

import java.util.HashSet;
import java.util.Set;

/**
 * Created by adam on 04.08.14.
 */
public class State {
    Set<Region> regions = new HashSet<>();
    private String name;

    public State(String name) {
        this.name = name;
    }

    public State addRegion(Region region){
        regions.add(region);
        return this;
    }

    public State removeRegion(Region region){
        regions.remove(region);
        return this;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
