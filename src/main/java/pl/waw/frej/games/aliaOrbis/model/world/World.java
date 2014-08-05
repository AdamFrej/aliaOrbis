package pl.waw.frej.games.aliaOrbis.model.world;

import java.util.HashSet;
import java.util.Set;

/**
 * Created by adam on 04.08.14.
 */
public class World {

    public Set<State> states = new HashSet<>();

    public World addState(State state) {
        states.add(state);
        return this;
    }

    public World removeState(State state) {
        states.remove(state);
        return this;
    }
}
