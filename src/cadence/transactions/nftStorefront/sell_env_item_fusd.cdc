import FungibleToken from "../../contracts/FungibleToken.cdc"
import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import FUSD from "../../contracts/FUSD.cdc"
import EnvironmentAct from "../../contracts/EnvironmentAct.cdc"
import NFTStorefront from "../../contracts/NFTStorefront.cdc"

transaction(saleItemID: UInt64, saleItemPrice: UFix64) {

    let environmentActProvider: Capability<&EnvironmentAct.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront

    prepare(account: AuthAccount) {
        // We need a provider capability, but one is not provided by default so we create one if needed.
        let environmentActCollectionProviderPrivatePath = /private/environmentActCollectionProvider

        if !account.getCapability<&EnvironmentAct.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(environmentActCollectionProviderPrivatePath)!.check() {
            account.link<&EnvironmentAct.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(environmentActCollectionProviderPrivatePath, target: EnvironmentAct.CollectionStoragePath)
        }

        self.environmentActProvider = account.getCapability<&EnvironmentAct.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(environmentActCollectionProviderPrivatePath)!

        assert(self.environmentActProvider.borrow() != nil, message: "Missing or mis-typed environmentAct.Collection provider")

        self.storefront = account.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    execute {
        self.storefront.createSaleOffer(
            nftProviderCapability: self.environmentActProvider,
            nftType: Type<@EnvironmentAct.NFT>(),
            nftID: saleItemID,
            salePrice: saleItemPrice
        )
    }
}
