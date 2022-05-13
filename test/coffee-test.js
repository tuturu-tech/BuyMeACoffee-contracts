const { expect } = require("chai");
const { ethers } = require("hardhat");

async function getBalance(address) {
	return await hre.waffle.provider.getBalance(address);
}

describe("BuyMeACoffee", function () {
	let coffee, owner, addr1, addr2;
	beforeEach(async function () {
		[owner, addr1, addr2] = await ethers.getSigners();
		const COFFEE = await hre.ethers.getContractFactory("BuyMeACoffee");
		coffee = await COFFEE.deploy();

		await coffee.deployed();
	});

	it("Should set the correct owner", async function () {
		expect(await coffee.owner()).to.equal(owner.address);
	});

	describe("buyCoffee", async function () {
		it("Should fail if no value is provided", async function () {
			await expect(
				coffee.buyCoffee("Alice", "Nice work!", { value: 0 })
			).to.be.revertedWith("can't buy coffee for free!");
		});

		it("Should correctly send value", async function () {
			const tip = ethers.utils.parseEther("1");
			const change = ethers.utils.parseEther("-1");
			await expect(
				await coffee.connect(addr1).buyCoffee("Bob", "Banging!", { value: tip })
			).to.changeEtherBalances([addr1, coffee], [change, tip]);
		});
	});

	describe("getMemos", async function () {
		it("Should correctly fetch memo", async function () {
			const tip = ethers.utils.parseEther("1");

			await expect(
				coffee.connect(addr1).buyCoffee("Bob", "Banging!", { value: tip })
			).to.not.be.reverted;
			const memos = await coffee.getMemos();

			for (const memo of memos) {
				expect(memo.name).to.equal("Bob");
				expect(memo.message).to.equal("Banging!");
				expect(memo.from).to.equal(addr1.address);
			}
		});
	});

	describe("withdrawTips", async function () {
		it("Should correctly withdraw", async function () {
			const tip = ethers.utils.parseEther("1");
			await expect(
				coffee.connect(addr1).buyCoffee("Bob", "Banging!", { value: tip })
			).to.not.be.reverted;

			await expect(await coffee.withdrawTips()).to.changeEtherBalance(
				owner,
				tip
			);
		});
	});
});
