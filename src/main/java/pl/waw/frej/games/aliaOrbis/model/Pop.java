package pl.waw.frej.games.aliaOrbis.model;

/**
 * Created by adam on 04.08.14.
 */
public class Pop {
    private final PopType popType;
    Integer workingPopulation;
    Integer totalPopulation;

    public Pop(PopType popType, Integer workingPopulation, Integer totalPopulation) {
        this.popType = popType;
        this.workingPopulation = workingPopulation;
        this.totalPopulation = totalPopulation;
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

}
