import { deployContractByName, executeScript, mintFlow, sendTransaction } from "flow-js-testing";

import { getKittyAdminAddress, getEnvActAdminAddress } from "./common";

// KittyItems types
export const typeID1 = 1000;

/*
 * Deploys NonFungibleToken and KittyItems contracts to KittyAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployKittyItems = async () => {
	const KittyAdmin = await getKittyAdminAddress();
	await mintFlow(KittyAdmin, "10.0");

	await deployContractByName({ to: KittyAdmin, name: "NonFungibleToken" });

	const addressMap = { NonFungibleToken: KittyAdmin };
	return deployContractByName({ to: KittyAdmin, name: "KittyItems", addressMap });
};

/*
 * Deploys NonFungibleToken and EnvAct contracts to EnvActAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deployEnvAct = async () => {
	const EnvActAdmin = await getEnvActAdminAddress();
	await mintFlow(EnvActAdmin, "10.0");

	await deployContractByName({ to: EnvActAdmin, name: "NonFungibleToken" });
	await deployContractByName({ to: EnvActAdmin, name: "FungibleToken" });
	await deployContractByName({ to: EnvActAdmin, name: "FUSD" });

	const addressMap = {
		NonFungibleToken: EnvActAdmin,
		FungibleToken: EnvActAdmin,
		FUSD: EnvActAdmin
	};

	await deployContractByName({ to: EnvActAdmin, name: "EnvironmentAct", addressMap });

	Object.assign(addressMap, {
		EnvironmentAct: EnvActAdmin
	})

	const result = await deployContractByName({ to: EnvActAdmin, name: "NFTStorefront", addressMap });
	return result;
};

/*
 * Setups EnvAct collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupEnvActOnAccount = async (account) => {
	const name = "environment/setup_account";
	const signers = [account];

	return sendTransaction({ name, signers });
};

/*
 * Setups KittyItems collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupKittyItemsOnAccount = async (account) => {
	const name = "kittyItems/setup_account";
	const signers = [account];

	return sendTransaction({ name, signers });
};

/*
 * Returns KittyItems supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getKittyItemSupply = async () => {
	const name = "kittyItems/get_kitty_items_supply";

	return executeScript({ name });
};

/*
 * Returns EnvAct collection
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getEnvActCollection = async (account) => {
	const name = "environment/get_collection_ids";
	const args = [account];

	return executeScript({ name, args });
};

/*
 * Mints KittyItem of a specific **itemType** and sends it to **recipient**.
 * @param {UInt64} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintKittyItem = async (itemType, recipient) => {
	const KittyAdmin = await getKittyAdminAddress();

	const name = "kittyItems/mint_kitty_item";
	const args = [recipient, itemType];
	const signers = [KittyAdmin];

	return sendTransaction({ name, args, signers });
};

/*
 * Mints EnvAct token and sends it to **recipient**.
 * @param {UInt64} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const minEnvActItem = async (recipient, issuer, metadata) => {
	const EnvActAdmin = await getEnvActAdminAddress();

	const name = "environment/mint_token";
	const args = [recipient, issuer, metadata];
	const signers = [EnvActAdmin];

	return sendTransaction({ name, args, signers });
};

/*
 * Returns EnvAct vault balance
 * @throws Will throw an error if execution will be halted
 * @returns {UFix64} - balance of vault
 * */
export const getEnvActVaultBalance = async (account) => {
	const name = "environment/get_account_vault";
	const args = [account];

	return executeScript({ name, args });
};

/*
 * Returns EnvAct token data
 * @throws Will throw an error if execution will be halted
 * @returns {} - token data
 * */
export const getEnvActTokenData = async (account, itemID) => {
	const name = "environment/get_env_item";
	const args = [account, itemID];

	return executeScript({ name, args });
};

/*
 * support token
 * @throws Will throw an error if execution will be halted
 * @returns {} - token data
 * */
export const supportToken = async (supporter, account, itemID) => {
	const name = "environment/support_token";
	const args = [account, itemID];
	const signers = [supporter];

	return sendTransaction({ name, args, signers });
};

/*
 * transfer token
 * @throws Will throw an error if execution will be halted
 * @returns {} 
 * */
export const transferToken = async (sender, receiver, itemID) => {
	const name = "environment/transfer_token";
	const args = [receiver, itemID];
	const signers = [sender];

	return sendTransaction({ name, args, signers });
};

/*
 * Transfers KittyItem NFT with id equal **itemId** from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {UInt64} itemId - id of the item to transfer
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const transferKittyItem = async (sender, recipient, itemId) => {
	const name = "kittyItems/transfer_kitty_item";
	const args = [recipient, itemId];
	const signers = [sender];

	return sendTransaction({ name, args, signers });
};

/*
 * Returns the KittyItem NFT with the provided **id** from an account collection.
 * @param {string} account - account address
 * @param {UInt64} itemID - NFT id
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getKittyItem = async (account, itemID) => {
	const name = "kittyItems/get_kitty_item";
	const args = [account, itemID];

	return executeScript({ name, args });
};

/*
 * Returns the number of Kitty Items in an account's collection.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getKittyItemCount = async (account) => {
	const name = "kittyItems/get_collection_length";
	const args = [account];

	return executeScript({ name, args });
};
