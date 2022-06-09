// Script1.cdc 
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

// Print the NFTs owned by account 0x02.
pub fun main(address: Address): [UInt64] {
    // Get the public account object for account
    let nftOwner = getAccount(address)

    log("/////////////////////")
    log(address);

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability<&EnvironmentAct.Collection{EnvironmentAct.EnvironmentActCollectionPublic}>(EnvironmentAct.CollectionPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    // Log the NFTs that they own as an array of IDs
    return receiverRef.getIDs();
}
 