const { ethers, upgrades } = require("hardhat");
const { expect } = require("chai");
const Promise = require("bluebird");
const fs = require("fs");
const path = require("path");

const deployContract = async (name) =>
  (await ethers.getContractFactory(name)).deploy();

before(async function () {
  signers = await ethers.getSigners();


  const Utilities = await ethers.getContractFactory('Utilities')
  const utils = await Utilities.deploy()
  await utils.deployed()
  console.log(`     Deployed Utilities at ${utils.address}`)

  const EightyColors = await ethers.getContractFactory('EightyColors')
  const eightyColors = await EightyColors.deploy()
  await eightyColors.deployed()
  console.log(`     Deployed EightyColors at ${eightyColors.address}`)

  const ChecksArt = await ethers.getContractFactory('ChecksArt', {
    libraries: {
      Utilities: utils.address,
      EightyColors: eightyColors.address,
    }
  })
  const checksArt = await ChecksArt.deploy()
  await checksArt.deployed()
  console.log(`     Deployed ChecksArt at ${checksArt.address}`)

  const ChecksMetadata = await ethers.getContractFactory('ChecksMetadata', {
    libraries: {
      Utilities: utils.address,
      ChecksArt: checksArt.address,
    }
  })
  const checksMetadata = await ChecksMetadata.deploy()
  await checksMetadata.deployed()
  console.log(`     Deployed ChecksMetadata at ${checksMetadata.address}`)

  var Checks = await ethers.getContractFactory('Checks', {
    libraries: {
      Utilities: utils.address,
      ChecksArt: checksArt.address,
      ChecksMetadata: checksMetadata.address,
    }
  })

  Checks = Checks.deployed();
  OldChecks = await deployContract("ZoraEdition");

	await OldChecks.setApprovalForAll(Checks.address, true);

  await OldChecks.mintArbitrary(0);
  await OldChecks.mintArbitrary(1);
  await OldChecks.mintArbitrary(2);
  await OldChecks.mintArbitrary(3);


  await Checks.mint([0,1,2,3]);

});

describe("Tests", async function () {
  it("Ensures non-admin cannot call admin functions", async function () {});
});
