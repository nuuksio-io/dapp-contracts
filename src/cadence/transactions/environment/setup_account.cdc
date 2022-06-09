import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

// This transaction configures an account to hold Environment Acts.

transaction {
    prepare(acct: AuthAccount) {
        // if the account doesn't already have a collection
        if acct.borrow<&EnvironmentAct.Collection>(from: EnvironmentAct.CollectionStoragePath) == nil {

            //Add exising FUSD or create a new one and add it
            let fusdReceiver = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
            if !fusdReceiver.check() {
                let fusd <- FUSD.createEmptyVault()
                acct.save(<- fusd, to: /storage/fusdVault)
                acct.link<&FUSD.Vault{FungibleToken.Receiver}>( /public/fusdReceiver, target: /storage/fusdVault)
                acct.link<&FUSD.Vault{FungibleToken.Balance}>( /public/fusdBalance, target: /storage/fusdVault)
            }

            let wallet = acct.getCapability<&{FungibleToken.Receiver}>(/public/fusdReceiver)
            
            // EnvAct collection
            let collection <- EnvironmentAct.createEmptyCollection()
            acct.save(<-collection, to: EnvironmentAct.CollectionStoragePath)
            acct.link<&EnvironmentAct.Collection{NonFungibleToken.CollectionPublic, EnvironmentAct.EnvironmentActCollectionPublic}>(EnvironmentAct.CollectionPublicPath, target: EnvironmentAct.CollectionStoragePath)

            // Profile user
            let profile <- EnvironmentAct.createUser(wallet: wallet)
            acct.save(<-profile, to: EnvironmentAct.ProfileStoragePath)
        
            // EnvAct vault
            let vault <- EnvironmentAct.createEmptyVault()
            acct.save(<-vault, to: EnvironmentAct.VaultStoragePath)
            acct.link<&EnvironmentAct.Vault{EnvironmentAct.EnvironmentActVaultPublic}>(EnvironmentAct.VaultPublicPath, target: EnvironmentAct.VaultStoragePath)

            // storefront
            let storefront <- NFTStorefront.createStorefront()
            acct.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)
            acct.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath, target: NFTStorefront.StorefrontStoragePath)
        }
    }
}
