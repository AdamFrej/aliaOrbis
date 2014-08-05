package pl.waw.frej.games.aliaOrbis.model.world;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.converters.extended.NamedMapConverter;
import org.apache.commons.io.FileUtils;
import pl.waw.frej.games.aliaOrbis.model.market.GoodType;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;

/**
 * Created by adam on 04.08.14.
 */
public class WorldFactory {

    public static World loadWorld() {
        World world = new World();
        try {
            world = (World) getxStream().fromXML(FileUtils.readFileToString(new File("target/resources/world.xml"), StandardCharsets.UTF_8));
        } catch (IOException e) {
            e.printStackTrace();
        }
        return world;
    }

    public static void saveWorld(World world) {
        try {
            FileUtils.writeStringToFile(new File("target/resources/save.xml"), getxStream().toXML(world), StandardCharsets.UTF_8);
        } catch (IOException e) {
            e.printStackTrace();
        }

    }

    public static World createTestWorld(){
        Pop newPop = new Pop(PopType.FARMERS,1,1);
        Province newProvince = new Province("prov");
        newProvince.addPop(newPop);
        Region newRegion = new Region("reg");
        newRegion.addProvince(newProvince);
        State newState = new State("state");
        newState.addRegion(newRegion);
        World newWorld = new World();
        newWorld.addState(newState);
        return newWorld;
    }

    private static XStream getxStream() {
        XStream xstream = new XStream();

        xstream.alias("world", World.class);
        xstream.addImplicitCollection(World.class, "states");

        xstream.alias("state", State.class);
        xstream.useAttributeFor(State.class, "name");
        xstream.addImplicitCollection(State.class, "regions");

        xstream.alias("region", Region.class);
        xstream.useAttributeFor(Region.class, "name");
        xstream.addImplicitCollection(Region.class, "provinces");

        xstream.alias("province", Province.class);
        xstream.useAttributeFor(Province.class, "name");
        xstream.addImplicitCollection(Province.class, "pops");

        xstream.alias("pop", Pop.class);
        xstream.useAttributeFor(Pop.class, "popType");

        NamedMapConverter ownedGoodsConverter = new NamedMapConverter(xstream.getMapper(),"good","type", GoodType.class,"quantity",Integer.class);
        xstream.registerConverter(ownedGoodsConverter);
        return xstream;
    }
}
