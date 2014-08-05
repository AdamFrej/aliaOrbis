package pl.waw.frej.games.aliaOrbis.model.world;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by adam on 04.08.14.
 */
public class Province {
    private Set<Pop> pops = new HashSet<>();
    private String name;

    public Province(String name) {
        this.name = name;
    }

    public Province addPop(Pop pop){
        pops.add(pop);
        return this;
    }

    public Province removePop(Pop pop){
        pops.remove(pop);
        return this;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Set<Pop> getPops() {
        return Collections.unmodifiableSet(pops);
    }
}
