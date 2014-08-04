package pl.waw.frej.games.aliaOrbis.model;

import com.thoughtworks.xstream.XStream;
import org.apache.commons.io.FileUtils;

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
            FileUtils.writeStringToFile(new File("target/resources/world.xml"), getxStream().toXML(world), StandardCharsets.UTF_8);
        } catch (IOException e) {
            e.printStackTrace();
        }

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
        return xstream;
    }
}
