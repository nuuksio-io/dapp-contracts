// Script1.cdc 
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

// Print the NFTs owned by account 0x02.
pub fun main(address: Address, itemID: UInt64): EnvActData {
    // Get the public account object for account
    let nftOwner = getAccount(address)

    // Find the public Receiver capability for their Collection
    let capability = nftOwner.getCapability<&EnvironmentAct.Collection{EnvironmentAct.EnvironmentActCollectionPublic}>(EnvironmentAct.CollectionPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    // Log the NFTs that they own as an array of IDs
    let token = receiverRef.borrowEnvironmentAct(id:itemID)!;
    let supporters:[Address] = []
    for key in token.supporters.keys {
        supporters.append(key)
    }
    return EnvActData(
        metadata: token.metadata,
        supporters: supporters,
        creator: token.creator
    ) 
}

pub struct EnvActData{
    pub let supporters: [Address]
    pub let metadata: {String: String}
    pub let creator: Address
    init(metadata: {String: String}, supporters: [Address], creator: Address) {
            self.metadata = metadata
            self.supporters = supporters
            self.creator = creator
        }
} 
 