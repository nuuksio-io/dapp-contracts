import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

pub fun main(address: Address): UFix64 {
    // Get the public account object for account
    let envAccount = getAccount(address)

    // Find the public vault capability
    let capability = envAccount.getCapability<&EnvironmentAct.Vault{EnvironmentAct.EnvironmentActVaultPublic}>(EnvironmentAct.VaultPublicPath)

    // borrow a reference from the capability
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    // return vault balance
    return receiverRef.getBalance()
}