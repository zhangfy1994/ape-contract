import * as fs from "node:fs";

const { ethers } = require("hardhat");

async function main() {
  const APENFT = await ethers.getContractFactory("APENFT");
  const aPENFT = await APENFT.deploy(
    "APENFT",
    "APENFT",
    100,
    1,
    Date.now() - 86400
  );

  await aPENFT.deployed();

  console.log("myERC20 deployed to:", aPENFT.address);

  const ownerAddress = await aPENFT.signer.getAddress();

  fs.writeFileSync(
    "./config.js",
    `
  export const contractAddress = "${aPENFT.address}"
  export const ownerAddress = "${ownerAddress}"
  `
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
