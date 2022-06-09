// Script1.cdc 
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

pub fun main(): UFix64 {
    return EnvironmentAct.getBalance();
}
 