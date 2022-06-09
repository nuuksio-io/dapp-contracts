import NFTStorefront from "../../contracts/NFTStorefront.cdc"

// This script returns the details for a sale offer within a storefront

pub fun main(address: Address, saleOfferResourceID: UInt64): NFTStorefront.SaleOfferDetails {
    let account = getAccount(address)
    let storefrontRef = account
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow public storefront from address")

    let saleOffer = storefrontRef.borrowSaleOffer(saleOfferResourceID: saleOfferResourceID)
        ?? panic("No item with that ID")
    
    return saleOffer.getDetails()
}
