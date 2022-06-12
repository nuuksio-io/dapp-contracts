
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

transaction(address: Address, itemID: UInt64) {
    prepare(supporter: AuthAccount) {

        let acc = getAccount(address)

        let accCapability = acc.getCapability<&{EnvironmentAct.EnvironmentActCollectionPublic}>(EnvironmentAct.CollectionPublicPath)

        // get user profile to support
        let userProfileRef = supporter.borrow<&EnvironmentAct.User>(from:EnvironmentAct.ProfileStoragePath)!

        let accRef = accCapability.borrow() ?? panic("could not borrow envAct collection reference")
        accRef.support(id: itemID, from: userProfileRef)
    }
}
