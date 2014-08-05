package pl.waw.frej.games.aliaOrbis.model.world;

import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * Created by adam on 04.08.14.
 */
public class Region {
    Set<Province> provinces = new HashSet<>();
    private String name;

    public Region(String name) {
        this.name = name;
    }

    public Region addProvince(Province province){
        provinces.add(province);
        return this;
    }

    public Region removeProvince(Province province){
        provinces.remove(province);
        return this;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Set<Province> getProvinces() {
        return Collections.unmodifiableSet(provinces);
    }
}
