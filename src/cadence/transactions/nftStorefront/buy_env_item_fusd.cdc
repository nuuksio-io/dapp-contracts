import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address) {

    let paymentVault: @EnvironmentAct.Vault
    let environmentActCollection: &EnvironmentAct.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let saleOffer: &NFTStorefront.SaleOffer{NFTStorefront.SaleOfferPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        let envActVault = account.borrow<&EnvironmentAct.Vault>(from: EnvironmentAct.VaultStoragePath)
            ?? panic("Cannot borrow EnvAct vault from account storage")

        let mainFUSDVault = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from account storage")

        // check if there is enough balance to purcahse token
        if (envActVault.getBalance() + mainFUSDVault.balance < price) {
                panic("Not enough balance to buy token")
        }

        self.paymentVault <- EnvironmentAct.createEmptyVault()
        
        // amount of tokens to be withdrawn from EnvAct vault
        // we will take all the payment amount if possible
        //  otherwise we will use the FUSD vault
        var envActAmount:UFix64 = price

        if(envActVault.getBalance() < price) {
            envActAmount = envActVault.getBalance()
        }
            
        var tempVault <- envActVault.withdraw(amount: envActAmount)
        self.paymentVault.topup(envActVault: <-tempVault)

        if(self.paymentVault.getBalance() < price) {
            let tempFusdVault <- mainFUSDVault.withdraw(amount: price - self.paymentVault.getBalance())
            let tempEnvActVault <- EnvironmentAct.createEmptyVault()
            tempEnvActVault.topupFUSD(vault: <-(tempFusdVault as! @FUSD.Vault))
            self.paymentVault.topup(envActVault: <-tempEnvActVault)
        }
        
        self.environmentActCollection = account.borrow<&EnvironmentAct.Collection{NonFungibleToken.Receiver}>(
            from: EnvironmentAct.CollectionStoragePath
        ) ?? panic("Cannot borrow envActs collection receiver from account")
    }

    execute {
        let item <- self.saleOffer.accept(
            envActPayment: <-self.paymentVault
        )

        self.environmentActCollection.deposit(token: <-item)

        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
}
