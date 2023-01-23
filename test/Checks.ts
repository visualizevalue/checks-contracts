import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { deployChecksFixture } from './fixtures/deploy'
import { mintedFixture } from './fixtures/mint'
import { composite } from './helpers/composite'
import { JALIL, VV, VV_TOKENS } from './helpers/constants'
import { render } from './helpers/render'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('Checks', () => {
  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecksFixture)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')

    expect(await checks.name()).to.equal('Checks')
    expect(await checks.symbol()).to.equal('Check')
  })

  describe('Mint', () => {
    it('Should allow to mint originals', async () => {
      const { checksEditions, checks, jalil } = await loadFixture(deployChecksFixture)

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
      const { checksEditions, checks, vv } = await loadFixture(deployChecksFixture)

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

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await checks.connect(vv).composite(toKeep, toBurn)

      const check = await checks.getCheck(toKeep)

      expect(check.composite[0]).to.equal(toBurn)
      expect(check.checksCount).to.equal(40)
      expect(check.divisorIndex).to.equal(1)
    })

    it('Should allow to composite many originals at once', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      await composite(VV_TOKENS.slice(0, 64), checks, vv)
    })

    it.skip('Should allow to composite and render many originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const [singleId, singleDivisor] = await composite(VV_TOKENS.slice(0, 64), checks, vv, 0, false)
      await render(singleId, singleDivisor, checks)

      const [fourId, fourDivisor] = await composite(VV_TOKENS.slice(64, 96), checks, vv, 0, false)
      await render(fourId, fourDivisor, checks)

      const [fiveId, fiveDivisor] = await composite(VV_TOKENS.slice(96, 112), checks, vv, 0, false)
      await render(fiveId, fiveDivisor, checks)

      const [tenId, tenDivisor] = await composite(VV_TOKENS.slice(112, 120), checks, vv, 0, false)
      await render(tenId, tenDivisor, checks)

      const [twentyId, twentyDivisor] = await composite(VV_TOKENS.slice(120, 124), checks, vv, 0, false)
      await render(twentyId, twentyDivisor, checks)

      const [fortyId, fortyDivisor] = await composite(VV_TOKENS.slice(124, 126), checks, vv, 0, false)
      await render(fortyId, fortyDivisor, checks)

      await render(VV_TOKENS[126], 80, checks)
    })
  })
})
