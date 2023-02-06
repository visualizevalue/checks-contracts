import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { deployChecks } from './fixtures/deploy'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('WithReveal', () => {
  let signers: SignerWithAddress[];

  before(async () => {
    signers = await ethers.getSigners()
  })

  it('Should mint unrevealed tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);

    await checksEditions.mintArbitrary(1)
    await checks.mint([1], signers[0].address)

    const beforeReveal = await checks.getCheck(1)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(5)
    expect((await checks.getCheck(1)).isRevealed).to.equal(false)
  })

  it('Should mint and reveal tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);

    await checksEditions.mintArbitrary(1)
    await checks.mint([1], signers[0].address)

    const beforeReveal = await checks.getCheck(1)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(5)
    await (await checks.advanceEpoch()).wait()

    const afterReveal = await checks.getCheck(1)
    expect(afterReveal.isRevealed).to.equal(true)
  })

  it('Should mint and auto-reveal tokens on new mints', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)
    await checksEditions.setApprovalForAll(checks.address, true);
    await checksEditions.mintAmount(2)

    await checks.mint([1], signers[0].address)
    const beforeReveal = await checks.getCheck(1)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(5)

    await checks.mint([2], signers[0].address)
    expect((await checks.getCheck(1)).isRevealed).to.equal(true)
    expect((await checks.getCheck(2)).isRevealed).to.equal(false)
  })
})
