import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { deployChecks } from './fixtures/deploy'
import { impersonateAccounts } from './fixtures/impersonate'
import { mintedFixture } from './fixtures/mint'
import { composite } from '../helpers/composite'
import { JALIL, VV, VV_TOKENS } from '../helpers/constants'
import { fetchAndRender, render } from '../helpers/render'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('Checks', () => {
  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecks)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')

    expect(await checks.name()).to.equal('Checks')
    expect(await checks.symbol()).to.equal('Check')
  })

  describe('Mint', () => {
    it('Should allow to mint originals', async () => {
      const { checksEditions, checks } = await loadFixture(deployChecks)
      const { jalil } = await loadFixture(impersonateAccounts)

      expect(await checks.totalSupply()).to.equal(0)

      await expect(checks.connect(jalil).mint([1001]))
        .to.be.revertedWith('Edition burn not approved')

      // First we need to approve the Originals contract on the Editions contract
      await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

      // Then we can mint one
      await expect(checks.connect(jalil).mint([1001]))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 1001)

      expect(await checks.totalSupply()).to.equal(1)

      // Or multiple
      await expect(checks.connect(jalil).mint([44, 222]))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 44)
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 222)

      expect(await checks.totalSupply()).to.equal(3)
    })

    it('Should allow to mint many originals at once', async () => {
      const { checksEditions, checks } = await loadFixture(deployChecks)
      const { vv } = await loadFixture(impersonateAccounts)

      await checksEditions.connect(vv).setApprovalForAll(checks.address, true)

      await expect(checks.connect(vv).mint(VV_TOKENS))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, VV, 9696)
    })
  })

  describe('Burning', () => {
    it('Should allow holders to just burn their tokens', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      expect(await checks.totalSupply()).to.equal(135)
      await checks.connect(vv).burn(VV_TOKENS[0])
      expect(await checks.totalSupply()).to.equal(134)
    })
  })

  describe('Compositing', () => {
    it('Should allow to composite originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      expect(await checks.totalSupply()).to.equal(135)

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await checks.connect(vv).composite(toKeep, toBurn)

      expect(await checks.totalSupply()).to.equal(134)

      const check = await checks.getCheck(toKeep)

      expect(check.composite[0]).to.equal(toBurn)
      expect(check.checksCount).to.equal(40)
      expect(check.divisorIndex).to.equal(1)
    })

    it('Should allow to composite many originals at once', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const totalSupply = await checks.totalSupply()
      expect(totalSupply).to.equal(135)

      await composite(VV_TOKENS.slice(0, 64), checks, vv)

      expect(await checks.totalSupply()).to.equal(totalSupply - 63) // One survives
    })

    it.skip('Should allow to composite and render many originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const [singleId] = await composite(VV_TOKENS.slice(0, 64), checks, vv, 0, false)
      await fetchAndRender(singleId, checks)

      const [fourId] = await composite(VV_TOKENS.slice(64, 96), checks, vv, 0, false)
      await fetchAndRender(fourId, checks)

      const [fiveId] = await composite(VV_TOKENS.slice(96, 112), checks, vv, 0, false)
      await fetchAndRender(fiveId, checks)

      const [tenId] = await composite(VV_TOKENS.slice(112, 120), checks, vv, 0, false)
      await fetchAndRender(tenId, checks)

      const [twentyId] = await composite(VV_TOKENS.slice(120, 124), checks, vv, 0, false)
      await fetchAndRender(twentyId, checks)

      const [fortyId] = await composite(VV_TOKENS.slice(124, 126), checks, vv, 0, false)
      await fetchAndRender(fortyId, checks)

      await fetchAndRender(VV_TOKENS[126], checks)
    })
  })
})
