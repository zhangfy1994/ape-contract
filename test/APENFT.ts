const { expect } = require("chai");
const { ethers } = require("hardhat");
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";

const tokenURI =
  "https://ipfs.io/ipfs/QmRL5ve3u7aN9RFMTmV1vWb6xsbyAYKDgkqyK9DCJJCaJD";

const account2 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

describe("APENFT", async function () {
  async function getAPENFT() {
    const APENFT = await ethers.getContractFactory("APENFT");

    const nft = await APENFT.deploy(
      "APENFT",
      "APENFT",
      100,
      1,
      Date.now() - 86400
    );
    await nft.deployed();

    return nft;
  }

  async function getDeployerAddress() {
    const [deployer] = await ethers.getSigners();
    const deployerAddress = await deployer.getAddress();

    return deployerAddress;
  }

  it("mintApe", async function () {
    const nft = await loadFixture(getAPENFT);
    const tx = await nft.mintApe(tokenURI);
    const receipt = await tx.wait();
    const total = await nft.totalSupply();

    expect(total).to.equal(1);
  });

  it("safeTransfer", async function () {
    const nft = await loadFixture(getAPENFT);
    await nft.mintApe(tokenURI);

    const deployerAddress = await getDeployerAddress();

    await nft.safeTransferFrom?.(deployerAddress, account2, 0);

    const owner = await nft.ownerOf(0);

    expect(owner).to.equal(account2);
  });
});
