import FungibleToken from "../../contracts/FungibleToken.cdc"
// import FUSD from "../../contracts/FUSD.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"

transaction(address: Address, amount: UFix64) {

  prepare(signer: AuthAccount) {
    // get admin refrence
    let adminRef = signer.borrow<&EnvironmentAct.NFTMinter>(from: EnvironmentAct.MinterStoragePath)!

    // Get a reference to the EnvAct vault's Receiver
    let EnvActVaultRef = getAccount(address).getCapability(EnvironmentAct.VaultPublicPath)
    .borrow<&{EnvironmentAct.EnvironmentActVaultPublic}>()
    ?? panic("Could not borrow receiver reference to the EnvAct Vault")

    // Withdraw tokens from the signer's stored vault
    EnvActVaultRef.withdrawFunds(amount: amount, ref: adminRef)
  }

}
