package pl.waw.frej.games.aliaOrbis.model.world;

import pl.waw.frej.games.aliaOrbis.model.market.GoodType;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

/**
 * Created by adam on 04.08.14.
 */
public class Pop {
    private final PopType popType;
    private Integer workingPopulation;
    private Integer totalPopulation;
    private Map<GoodType,Integer> ownedGoods = new HashMap<>();

    public Pop(PopType popType, Integer workingPopulation, Integer totalPopulation) {
        this.popType = popType;
        this.workingPopulation = workingPopulation;
        this.totalPopulation = totalPopulation;


        for(GoodType goodType : GoodType.values()){
            ownedGoods.put(goodType,0);
        }
    }

    public PopType getPopType() {
        return popType;
    }

    public Integer getWorkingPopulation() {
        return workingPopulation;
    }

    public Integer getTotalPopulation() {
        return totalPopulation;
    }

    public Map<GoodType, Integer> getOwnedGoods() {
        return Collections.unmodifiableMap(ownedGoods);
    }

    public Integer getGoodQuantity(GoodType goodType){
        return ownedGoods.get(goodType);
    }

    public void setGoodQuantity(GoodType goodType, Integer quantity){
        ownedGoods.replace(goodType,quantity);
    }

}
