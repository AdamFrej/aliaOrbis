package pl.waw.frej.games.aliaOrbis.model.market;

import pl.waw.frej.games.aliaOrbis.model.world.*;

/**
 * Created by adam on 05.08.14.
 */
public class ProvinceMarket {

    public void ProvinceTrade(World world) {
        for(State state : world.states) {
            for(Region region : state.getRegions()) {
                for(Province province : region.getProvinces()) {

                    for(Pop pop : province.getPops()) {
                        if(pop.getOwnedGoods().get(GoodType.GRAIN)>10){
                            
                        }
                    }
                }
            }
        }
    }
}
