const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const Promise = require("bluebird");
const fs = require("fs");
const path = require("path");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

const deployContract = async (name) =>
  (await ethers.getContractFactory(name)).deploy();

var Checks;
var owner;

before(async function () {
  signers = await ethers.getSigners();

  owner = signers[0];

  const Utilities = await ethers.getContractFactory("Utilities");
  const utils = await Utilities.deploy();
  await utils.deployed();
  console.log(`     Deployed Utilities at ${utils.address}`);

  const EightyColors = await ethers.getContractFactory("EightyColors");
  const eightyColors = await EightyColors.deploy();
  await eightyColors.deployed();
  console.log(`     Deployed EightyColors at ${eightyColors.address}`);

  const ChecksArt = await ethers.getContractFactory("ChecksArt", {
    libraries: {
      Utilities: utils.address,
      EightyColors: eightyColors.address,
    },
  });
  const checksArt = await ChecksArt.deploy();
  await checksArt.deployed();
  console.log(`     Deployed ChecksArt at ${checksArt.address}`);

  const ChecksMetadata = await ethers.getContractFactory("ChecksMetadata", {
    libraries: {
      Utilities: utils.address,
      ChecksArt: checksArt.address,
    },
  });
  const checksMetadata = await ChecksMetadata.deploy();
  await checksMetadata.deployed();
  console.log(`     Deployed ChecksMetadata at ${checksMetadata.address}`);

  Checks = await ethers.getContractFactory("Checks", {
    libraries: {
      Utilities: utils.address,
      ChecksArt: checksArt.address,
      ChecksMetadata: checksMetadata.address,
    },
  });

  OldChecks = await deployContract("ZoraEdition");
  console.log(`     Deployed OldChecks at ${OldChecks.address}`);

  Checks = await (await Checks.deploy(OldChecks.address)).deployed();
  console.log(`     Deployed Checks at ${Checks.address}`);

  await OldChecks.setApprovalForAll(Checks.address, true);

  await OldChecks.mintArbitraryAmount(100);
});

async function logAllEpochs() {
  const currentEpoch = parseInt(await Checks.epochIndex());

  const numberOfEpochs = currentEpoch;


  for (var i = 1; i < numberOfEpochs + 1; i++) {
    const epoch = await Checks.epochs(i);
    console.log(
`
-----------------
EPOCH ${i}
REVEAL BLOCK NUMBER: ${epoch.revealBlock}
RANDOMNESS: ${epoch.randomness}
COMMITED: ${epoch.commited}
REVEALED: ${epoch.revealed}
-----------------
`);
  }

}

describe("Tests", async function () {
  it("Tests minting", async function () {
    await mine(257);

    await Checks.mint([0, 1, 2, 3], owner.address);

    await mine(5)

    await Checks.mint([4, 5, 6, 7, 8], owner.address);

    
    await mine(2)

    await Checks.mint([9, 10, 11, 12, 13], owner.address);

    await mine(200)

    await Checks.mint([14, 15, 16, 17, 18], owner.address);

    await logAllEpochs();
  });
});
