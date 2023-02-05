const { ethers } = require("hardhat");
const { expect } = require("chai");
const Promise = require("bluebird");
const {sloth} = require('./slothVDF');


const deployContract = async (name) =>
  (await ethers.getContractFactory(name)).deploy();

  before(async function () {
    // We get the signer
    const [signer] = await ethers.getSigners();
   
    // get the contracts
    const Randomizer = await deployContract("Randomizer");

   
    // the prime and iterations from the contract
    const prime = BigInt((await Randomizer.prime()).toString());
    const iterations = BigInt((await Randomizer.iterations()).toNumber());
    console.log('prime', prime.toString());
    console.log('iterations', iterations.toString());
   
    // create a new seed
    const epoch = 0;
    const tx = await Randomizer.advanceEpoch();
    await tx.wait();
   
    // get the seed
    const seed = BigInt((await Randomizer.getSeedForEpoch(epoch)).toString());
    console.log('seed', seed.toString());
   
    // compute the proof
    const start = Date.now();
    const proof = sloth.compute(seed, prime, iterations);
    console.log('compute time', Date.now() - start, 'ms', 'vdf proof', proof);
   
    // this could be a mint function, etc
    const proofTx = await Randomizer.solveEpoch(proof,  epoch);
    await proofTx.wait();

});
   
describe("Tests", async function () {
    it("test1", async function(){
        console.log("Test1")
    });
});