import NonFungibleToken from "./NonFungibleToken.cdc"
import FungibleToken from "./FungibleToken.cdc"
import FUSD from "./FUSD.cdc"

// EnvironmentAct
// NFT item
//
pub contract EnvironmentAct: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, metadata: {String:String})
    pub event EnvironmentActCreated(id: UInt64, metadata: {String:String})
    pub event supportAct(id: UInt64, address: Address)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let ProfileStoragePath: StoragePath
    pub let ProfilePublicPath: PublicPath     
    pub let VaultStoragePath: StoragePath
    pub let VaultPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of EnvironmentActs that have been minted
    //
    pub var totalSupply: UInt64
    pub var totalVerified: UInt64

    // feedback vault
    access(account) let vault: @FUSD.Vault

    // struct for supporters
    // we can add more properties later
    pub struct UserProfile {
		pub let wallet:Capability<&{FungibleToken.Receiver}> 
        pub let address: Address

		init(
            wallet:Capability<&{FungibleToken.Receiver}>,
            address: Address
        ){
			self.address=address
            self.wallet=wallet
		}
	}

    // user profile
    pub resource User {
        pub var verified: Bool
		pub let wallet:Capability<&{FungibleToken.Receiver}>
        init(
            wallet:Capability<&{FungibleToken.Receiver}>
        ){
            self.verified = false
            self.wallet = wallet
        }

        pub fun getProfile(address: Address): UserProfile {
          return UserProfile(wallet: self.wallet, address: address)
        }
    }

    // NFT
    // An EnvironmentAct Item as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        // Stores all the metadata about the environment action as a string mapping
        // This is not the long term way NFT metadata will be stored. It's a temporary
        // construct while we figure out a better way to do metadata.
        //
        pub let metadata: {String: String}

        pub let creator: Address

        pub let supporters: { Address: UserProfile }

        pub let createdAt: UFix64

        // initializer
        //
        init(initID: UInt64, metadata: {String: String}, creator: Address) {
            pre {
                metadata.length != 0: "EnvironmentAct metadata cannot be empty"
            }            
            self.id = initID
            self.metadata = metadata
            self.supporters = {}
            self.createdAt = getCurrentBlock().timestamp
            self.creator = creator

            emit EnvironmentActCreated(id: initID, metadata: metadata)
        }
    }

    // This is the interface that users can cast their EnvironmentAct Collection as
    // to allow others to deposit EnvironmentAct into their Collection. It also allows for reading
    // the details of EnvironmentActs in the Collection.
    pub resource interface EnvironmentActCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun support(id: UInt64, from: &User)
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowEnvironmentAct(id: UInt64): &EnvironmentAct.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow EnvironmentAct reference: The ID of the returned reference is incorrect"
            }
        }

        pub fun getMetadata(id: UInt64): {String: String}?
        pub fun getSupporters(id: UInt64): { Address: UserProfile }?
    }

    // deposit funds into EnvAct vault
    pub fun topup(vault: @FUSD.Vault) {
        self.vault.deposit(from: <-vault)
    }

    // get vault balance
    pub fun getBalance(): UFix64 {
        return self.vault.balance
    }

    // Collection
    // A collection of EnvironmentAct NFTs owned by an account
    //
    pub resource Collection: EnvironmentActCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @EnvironmentAct.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // support token
        pub fun support(id: UInt64, from: &User){
            pre {
                // from.verified : "Unverified users are not allowed to support"
                self.ownedNFTs[id] != nil: "No token with this id"
            }

            let envAct = self.borrowEnvironmentAct(id: id)!
            let address = from.owner!.address
            let userProfile = from.getProfile(address: address)
            envAct.supporters[address] = userProfile
            emit supportAct(id:id, address:address)
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowEnvironmentAct
        // Gets a reference to an NFT in the collection as an EnvironmentAct,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the EnvironmentAct.
        //
        pub fun borrowEnvironmentAct(id: UInt64): &EnvironmentAct.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &EnvironmentAct.NFT
            } else {
                return nil
            }
        }

        pub fun getMetadata(id: UInt64): {String: String}? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                let nft = ref as! &EnvironmentAct.NFT
                return nft.metadata
            } else {
                return nil
            }
        }

        pub fun getSupporters(id: UInt64): { Address: UserProfile }? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                let nft = ref as! &EnvironmentAct.NFT
                return nft.supporters
            } else {
                return nil
            }
        }        

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    pub resource interface EnvironmentActVaultPublic {
        pub fun topup(envActVault: @Vault)
        pub fun getBalance(): UFix64
        pub fun topupFUSD(vault: @FUSD.Vault)
        pub fun withdraw(amount: UFix64): @Vault
        access(account) fun withdrawFUSD(amount: UFix64): @FUSD.Vault
        pub fun withdrawFunds(amount: UFix64, ref: &NFTMinter)
    }

    // A special vault that wrap-up inside a FUSD vault
    // which restrict the usage of those funds
    // to be used only in the EnvAct marketplace
    pub resource Vault: EnvironmentActVaultPublic {
        // vault for storing funds from purchasing the EnvAct tokens
        access(contract) let vault: @FUSD.Vault

        pub fun topup(envActVault: @Vault) {
            let fusdVault <- envActVault.vault.withdraw(amount: envActVault.getBalance())
            self.vault.deposit(from: <-fusdVault)
            destroy envActVault
        }

        pub fun topupFUSD(vault: @FUSD.Vault) {
            self.vault.deposit(from: <-vault)
        }

        pub fun withdraw(amount: UFix64): @Vault {
            let envActVault <-create Vault()
            envActVault.vault.deposit(from: <-self.vault.withdraw(amount: amount))
            return <-envActVault
        }

        access(account) fun withdrawFUSD(amount: UFix64): @FUSD.Vault{
            return <- (self.vault.withdraw(amount: amount) as! @FUSD.Vault)
        }

        pub fun withdrawFunds(amount: UFix64, ref: &NFTMinter) {
          // assert(ref != nil, "Ref admin is bad")
          let vault <- self.vault.withdraw(amount: amount)
          EnvironmentAct.vault.deposit(from: <-vault)
        }

        pub fun getBalance(): UFix64{
            return self.vault.balance;
        }

        // initializer
        //
        init () {
            self.vault <-FUSD.createEmptyVault()
        }

        // destructor
        destroy() {
            destroy self.vault
        }
    }

    // createEmptyVault
    // EnvAct vault: some sale cuts will go here
    // which allow the owner to reinvest in other tokens
    pub fun createEmptyVault(): @Vault {
        return <-create Vault()
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // create user
    pub fun createUser(wallet:Capability<&{FungibleToken.Receiver}>): @User {
        return <- create User(wallet: wallet)
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource NFTMinter {

		// mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, metadata: {String : String}) {
            emit Minted(id: EnvironmentAct.totalSupply, metadata: metadata)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create EnvironmentAct.NFT(initID: EnvironmentAct.totalSupply, metadata: metadata, creator: recipient.owner!.address))

            EnvironmentAct.totalSupply = EnvironmentAct.totalSupply + (1 as UInt64)
		}
	}

    // fetch
    // Get a reference to a EnvironmentAct from an account's Collection, if available.
    // If an account does not have a EnvironmentAct.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &EnvironmentAct.NFT? {
        let collection = getAccount(from)
            .getCapability(EnvironmentAct.CollectionPublicPath)
            .borrow<&EnvironmentAct.Collection{EnvironmentAct.EnvironmentActCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust EnvironmentAct.Collection.borowEnvironmentAct to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowEnvironmentAct(id: itemID)
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.CollectionStoragePath = /storage/environmentActCollection
        self.CollectionPublicPath = /public/environmentActCollection
        self.ProfileStoragePath = /storage/environmentActProfile
        self.ProfilePublicPath = /public/environmentActProfile
        self.VaultStoragePath = /storage/environmentActVault
        self.VaultPublicPath = /public/environmentActVault
        self.MinterStoragePath = /storage/environmentActMinter

        // Initialize the total supply
        self.totalSupply = 0
        self.totalVerified = 0

        // initialize vault
        self.vault <-FUSD.createEmptyVault()

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        // setup EnvAct collection
        // this collection is useful for admin to be an escrow
        let collection <- self.createEmptyCollection()
        self.account.save(<-collection, to: self.CollectionStoragePath)
        self.account.link<&EnvironmentAct.Collection{NonFungibleToken.CollectionPublic, EnvironmentAct.EnvironmentActCollectionPublic}>(self.CollectionPublicPath, target: self.CollectionStoragePath)

        emit ContractInitialized()
	}
}