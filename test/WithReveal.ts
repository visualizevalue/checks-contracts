import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { Contract } from 'ethers'
import { deployChecks } from './fixtures/deploy'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('WithReveal', () => {
  let signers: SignerWithAddress[];
  let signer: SignerWithAddress

  before(async () => {
    signers = await ethers.getSigners()
    signer = signers[0]
  })

  it('Should mint unrevealed tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);

    await checksEditions.mintArbitrary(1)
    await checks.mint([1], signer.address)

    const beforeReveal = await checks.getCheck(1)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(5)
    expect((await checks.getCheck(1)).isRevealed).to.equal(false)

    const firstEpoch = await checks.getEpoch(1)
    const secondEpoch = await checks.getEpoch(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(false)
    expect(secondEpoch.committed).to.equal(false)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and reveal tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);

    await checksEditions.mintArbitrary(1)
    await checks.mint([1], signer.address)

    await mine(5)
    await (await checks.resolveEpochIfNecessary()).wait()

    const afterReveal = await checks.getCheck(1)
    expect(afterReveal.isRevealed).to.equal(true)

    const firstEpoch = await checks.getEpoch(1)
    const secondEpoch = await checks.getEpoch(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and auto-reveal tokens on new mints', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);
    await checksEditions.mintAmount(4)

    await checks.mint([1, 2], signer.address)
    await mine(5)

    await checks.mint([3, 4], signer.address)
    expect((await checks.getCheck(1)).isRevealed).to.equal(true)
    expect((await checks.getCheck(2)).isRevealed).to.equal(true)
    expect((await checks.getCheck(3)).isRevealed).to.equal(false)
    expect((await checks.getCheck(4)).isRevealed).to.equal(false)

    const firstEpoch = await checks.getEpoch(1)
    const secondEpoch = await checks.getEpoch(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should extend a previous commitment', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);
    await checksEditions.mintAmount(3)

    await checks.mint([1], signer.address)
    await mine(261)

    await checks.mint([2], signer.address)
    expect((await checks.getCheck(1)).isRevealed).to.equal(false)
    expect((await checks.getCheck(2)).isRevealed).to.equal(false)

    await mine(5)
    await checks.mint([3], signer.address)

    expect((await checks.getCheck(1)).isRevealed).to.equal(true)
    expect((await checks.getCheck(2)).isRevealed).to.equal(true)

    const firstEpoch = await checks.getEpoch(1)
    const secondEpoch = await checks.getEpoch(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should allow manually creating new epochs between mints', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);
    await checksEditions.mintAmount(3)

    await checks.mint([1], signer.address)
    expect(await checks.epochIndex()).to.equal(1)
    await mine(5)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect(await checks.epochIndex()).to.equal(2)
    await mine(5)
    await (await checks.resolveEpochIfNecessary()).wait()
    await (await checks.resolveEpochIfNecessary()).wait()
    await (await checks.resolveEpochIfNecessary()).wait()
    expect(await checks.epochIndex()).to.equal(3)
    await mine(5)
    await checks.mint([2], signer.address)
    expect(await checks.epochIndex()).to.equal(4)
    await mine(5)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect(await checks.epochIndex()).to.equal(5)
    await mine(261)
    await checks.mint([3], signer.address)
    expect(await checks.epochIndex()).to.equal(5)
    await mine(3)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect((await checks.getCheck(3)).isRevealed).to.equal(false)
    expect(await checks.epochIndex()).to.equal(5)
    await mine(5)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect(await checks.epochIndex()).to.equal(6)
    await mine(5)

    expect((await checks.getCheck(1)).isRevealed).to.equal(true)
    expect((await checks.getCheck(2)).isRevealed).to.equal(true)
    expect((await checks.getCheck(3)).isRevealed).to.equal(true)

    let epoch = await checks.getEpoch(1)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpoch(4)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpoch(5)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpoch(6)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(false)
  })
})

async function logAllEpochs (checks: Contract) {
  const currentEpoch = parseInt(await checks.epochIndex());

  const numberOfEpochs = currentEpoch;


  for (var i = 1; i < numberOfEpochs + 1; i++) {
    const epoch = await checks.getEpoch(i);
    console.log(
`
-----------------
EPOCH ${i}
REVEAL BLOCK NUMBER: ${epoch.revealBlock}
RANDOMNESS: ${epoch.randomness}
COMMITED: ${epoch.committed}
REVEALED: ${epoch.revealed}
-----------------
`);
  }

}
