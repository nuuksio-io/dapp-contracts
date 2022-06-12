import path from "path";

import { emulator, init, getAccountAddress, shallPass } from "flow-js-testing";

import { toUFix64, getEnvActAdminAddress } from "../src/common";
import { mintKibble } from "../src/kibble";
import { getKittyItemCount, mintKittyItem, getKittyItem, typeID1 } from "../src/kitty-items";
import {
	deployNFTStorefront,
	buyItem,
	sellItem,
	removeItem,
	setupStorefrontOnAccount,
	getSaleOfferCount,
	getSaleOffers,
	getSaleOfferItem
} from "../src/nft-storefront";

import {
	deployEnvAct,
	setupEnvActOnAccount,
	minEnvActItem,
	getEnvActCollection,
	getEnvActVaultBalance,
	getEnvActTokenData,
	supportToken,
	transferToken
} from "../src/environment";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(500000);

describe("NFT Storefront", () => {
	beforeAll(async () => {
		const basePath = path.resolve(__dirname, "../../../");
		const port = 7003;
		await init(basePath, { port });
		return emulator.start(port, false);
	});

	// Stop emulator, so it could be restarted
	afterAll(async () => {
		return emulator.stop();
	});

	it("shall deploy EnvAct NFTStorefront contract and create storeFront", async () => {
		await shallPass(deployEnvAct());
		const Alice = await getAccountAddress("Alice");
		await shallPass(setupEnvActOnAccount(Alice));
		const offersCount = await getSaleOfferCount(Alice);
		const offers = await getSaleOffers(Alice);
		expect(offersCount[0]).toBe(0);
		expect(offers[0].length).toBe(0);
	});

	it("shall be able to create a sale offer and get it", async () => {
		// Setup
		const Alice = await getAccountAddress("Alice");
		await setupStorefrontOnAccount(Alice);

		const envActAdmin = await getEnvActAdminAddress();
		await shallPass(minEnvActItem(Alice, envActAdmin, { name: "token for sale" }));

		const itemID = 0;

		await shallPass(sellItem(Alice, itemID, toUFix64(1.11)));

		const offersCount = await getSaleOfferCount(Alice);
		const offers = await getSaleOffers(Alice);
		expect(offersCount[0]).toBe(1);
		expect(offers[0].length).toBe(1);
	});

	it("shall be able to get sale offer details", async () => {
		// Setup
		const Alice = await getAccountAddress("Alice");
		const offers = await getSaleOffers(Alice);

		const saleofferDetails = await getSaleOfferItem(Alice, offers[0][0]);
		expect(saleofferDetails[0].itemID).toBe(0);
		expect(saleofferDetails[0].price).toBe('1.11000000');
		expect(saleofferDetails[0].owner).toBe(Alice);
	});

	/* it("shall be able to accept a sale offer", async () => {
		// Setup
		await deployNFTStorefront();
	
		// Setup seller account
		const Alice = await getAccountAddress("Alice");
		await setupStorefrontOnAccount(Alice);
		await mintKittyItem(typeID1, Alice);
	
		const itemId = 0;
	
		// Setup buyer account
		const Bob = await getAccountAddress("Bob");
		await setupStorefrontOnAccount(Bob);
	
		await shallPass(mintKibble(Bob, toUFix64(100)));
	
		// Bob shall be able to buy from Alice
		const sellItemTransactionResult = await shallPass(sellItem(Alice, itemId, toUFix64(1.11)));
	
		const saleOfferAvailableEvent = sellItemTransactionResult.events[0];
		const saleOfferResourceID = saleOfferAvailableEvent.data.saleOfferResourceID;
	
		await shallPass(buyItem(Bob, saleOfferResourceID, Alice));
	
		const itemCount = await getKittyItemCount(Bob);
		expect(itemCount).toBe(1);
	
		const offerCount = await getSaleOfferCount(Alice);
		expect(offerCount).toBe(0);
	});
	
	it("shall be able to remove a sale offer", async () => {
		// Deploy contracts
		await shallPass(deployNFTStorefront());
	
		// Setup Alice account
		const Alice = await getAccountAddress("Alice");
		await shallPass(setupStorefrontOnAccount(Alice));
	
		// Mint instruction shall pass
		await shallPass(mintKittyItem(typeID1, Alice));
	
		const itemId = 0;
	
		const item = await getKittyItem(Alice, itemId);
	
		// Listing item for sale shall pass
		const sellItemTransactionResult = await shallPass(sellItem(Alice, itemId, toUFix64(1.11)));
	
		const saleOfferAvailableEvent = sellItemTransactionResult.events[0];
		const saleOfferResourceID = saleOfferAvailableEvent.data.saleOfferResourceID;
	
		// Alice shall be able to remove item from sale
		await shallPass(removeItem(Alice, saleOfferResourceID));
	
		const offerCount = await getSaleOfferCount(Alice);
		expect(offerCount).toBe(0);
	});*/

});
