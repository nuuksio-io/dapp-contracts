import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleOfferResourceID: UInt64, storefrontAddress: Address, recipient: Address) {

    let paymentVault: @EnvironmentAct.Vault
    let environmentActCollection: &EnvironmentAct.Collection{EnvironmentAct.EnvironmentActCollectionPublic}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let saleOffer: &NFTStorefront.SaleOffer{NFTStorefront.SaleOfferPublic}

    prepare(account: AuthAccount) {
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        self.saleOffer = self.storefront.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)
            ?? panic("No Offer with that ID in Storefront")
        
        let price = self.saleOffer.getDetails().salePrice

        let mainFUSDVault = account.borrow<&FUSD.Vault>(from: /storage/fusdVault)
            ?? panic("Cannot borrow FUSD vault from account storage")

        // create payment vault
        self.paymentVault <- EnvironmentAct.createEmptyVault()
        let tempFusdVault <- mainFUSDVault.withdraw(amount: price)
        let tempEnvActVault <- EnvironmentAct.createEmptyVault()
        tempEnvActVault.topupFUSD(vault: <-(tempFusdVault as! @FUSD.Vault))
        self.paymentVault.topup(envActVault: <-tempEnvActVault)
        
        // get recipient collection ref
        self.environmentActCollection = getAccount(recipient).getCapability(EnvironmentAct.CollectionPublicPath)
            .borrow<&EnvironmentAct.Collection{EnvironmentAct.EnvironmentActCollectionPublic}>()
        ?? panic("Cannot borrow envActs collection receiver".concat(recipient.toString()))
    }

    execute {
        let item <- self.saleOffer.accept(
            envActPayment: <-self.paymentVault
        )

        self.environmentActCollection.deposit(token: <-item)

        self.storefront.cleanup(saleOfferResourceID: saleOfferResourceID)
    }
}