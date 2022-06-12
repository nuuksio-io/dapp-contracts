import path from "path";

import { emulator, init, getAccountAddress, shallPass, shallResolve, shallRevert } from "flow-js-testing";

import { getKittyAdminAddress, getEnvActAdminAddress } from "../src/common";
import {
	deployKittyItems,
	getKittyItem,
	getKittyItemCount,
	getKittyItemSupply,
	mintKittyItem,
	setupKittyItemsOnAccount,
	transferKittyItem,
	typeID1,
} from "../src/kitty-items";

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
jest.setTimeout(50000);

describe("EnvAct testing", () => {
	// Instantiate emulator and path to Cadence files
	beforeAll(async () => {
		const basePath = path.resolve(__dirname, "../../../");
		const port = 7002;
		await init(basePath, { port });
		return emulator.start(port, false);
	});

	// Stop emulator, so it could be restarted
	afterAll(async () => {
		return emulator.stop();
	});

	it("shall deploy EnvAct contract and mint NFT by admin account", async () => {
		await deployEnvAct();
		const envActAdmin = await getEnvActAdminAddress();
		await shallPass(minEnvActItem(envActAdmin, envActAdmin, { name: "test token" }));
		const result = await getEnvActCollection(envActAdmin);
		expect(result[0].length).toBe(1);
	});

	it("shall deploy EnvAct contract and setup account collection must be empty", async () => {
		// await deployEnvAct();
		const Alice = await getAccountAddress("Alice");
		await shallPass(setupEnvActOnAccount(Alice));
		const result = await getEnvActCollection(Alice);
		expect(result[0].length).toBe(0);
	});

	it("resetting up an account should not fail", async () => {
		// await deployEnvAct();
		const Alice = await getAccountAddress("Alice");
		// await shallPass(setupEnvActOnAccount(Alice));
		await shallPass(setupEnvActOnAccount(Alice));
	});

	it("mint and transfer NFT to an account's collection", async () => {
		// await deployEnvAct();
		const Alice = await getAccountAddress("Alice");
		const envActAdmin = await getEnvActAdminAddress();
		// await shallPass(setupEnvActOnAccount(Alice));
		await shallPass(minEnvActItem(Alice, envActAdmin, { name: "transfer token" }));
		const result = await getEnvActCollection(Alice);
		expect(result[0].length).toBe(1);
	});

	it("check the EnvAct vault readiness after setup", async () => {
		// await deployEnvAct();
		const Alice = await getAccountAddress("Alice");
		// await shallPass(setupEnvActOnAccount(Alice));
		const result = await getEnvActVaultBalance(Alice);
		expect(result[0]).toBe("0.00000000");
	});

	/* it("Transfer envAct token from one account to another", async () => {
		// await deployEnvAct();
		const Bob = await getAccountAddress("Bob");
		await shallPass(setupEnvActOnAccount(Bob));
		const Alice = await getAccountAddress("Alice");
	}); */

	it("get envAct token data (metadata, supporters, creator)", async () => {
		// await deployEnvAct();
		const Alice = await getAccountAddress("Alice");
		const collectionIds = await getEnvActCollection(Alice);
		const envActTokenData = await getEnvActTokenData(Alice, collectionIds[0][0]);
		expect(envActTokenData[0].supporters.length).toBe(0);
		expect(envActTokenData[0].creator).toBe(Alice);
	});

	it("support envAct Token", async () => {
		// await deployEnvAct();
		const Bob = await getAccountAddress("Bob");
		await setupEnvActOnAccount(Bob);
		const Alice = await getAccountAddress("Alice");
		const collectionIds = await getEnvActCollection(Alice);
		await shallPass(supportToken(Bob, Alice, collectionIds[0][0]));
		const envActTokenData = await getEnvActTokenData(Alice, collectionIds[0][0]);
		expect(envActTokenData[0].supporters.length).toBe(1);
		expect(envActTokenData[0].supporters[0]).toBe(Bob);
	});

	// transfer token	
	it("shall not be able to withdraw an NFT that doesn't exist in a collection", async () => {
		// Setup
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");

		// Transfer transaction shall fail for non-existent item
		await shallRevert(transferToken(Bob, Alice, 1));

		// Transfer transaction shall pass for non-existent item
		await shallPass(transferToken(Alice, Bob, 1));
	});

	/* it("supply shall be 0 after contract is deployed", async () => {
		// Setup
		await deployKittyItems();
		const KittyAdmin = await getKittyAdminAddress();
		await shallPass(setupKittyItemsOnAccount(KittyAdmin));

		await shallResolve(async () => {
			const supply = await getKittyItemSupply();
			expect(supply).toBe(0);
		});
	});

	it("shall be able to mint a kittyItems", async () => {
		// Setup
		await deployKittyItems();
		const Alice = await getAccountAddress("Alice");
		await setupKittyItemsOnAccount(Alice);
		const itemIdToMint = typeID1;

		// Mint instruction for Alice account shall be resolved
		await shallPass(mintKittyItem(itemIdToMint, Alice));
	});

	it("shall be able to create a new empty NFT Collection", async () => {
		// Setup
		await deployKittyItems();
		const Alice = await getAccountAddress("Alice");
		await setupKittyItemsOnAccount(Alice);

		// shall be able te read Alice collection and ensure it's empty
		await shallResolve(async () => {
			const itemCount = await getKittyItemCount(Alice);
			expect(itemCount).toBe(0);
		});
	});

	it("shall not be able to withdraw an NFT that doesn't exist in a collection", async () => {
		// Setup
		await deployKittyItems();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		await setupKittyItemsOnAccount(Alice);
		await setupKittyItemsOnAccount(Bob);

		// Transfer transaction shall fail for non-existent item
		await shallRevert(transferKittyItem(Alice, Bob, 1337));
	});

	it("shall be able to withdraw an NFT and deposit to another accounts collection", async () => {
		await deployKittyItems();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		await setupKittyItemsOnAccount(Alice);
		await setupKittyItemsOnAccount(Bob);

		// Mint instruction for Alice account shall be resolved
		await shallPass(mintKittyItem(typeID1, Alice));

		// Transfer transaction shall pass
		await shallPass(transferKittyItem(Alice, Bob, 0));
	}); */
});
