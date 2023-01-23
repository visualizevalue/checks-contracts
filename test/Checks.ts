import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { deployChecksFixture } from './fixtures/deploy'
import { mintedFixture } from './fixtures/mint'
import { composite } from './helpers/composite'
import { JALIL, VV, VV_TOKENS } from './helpers/constants'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('Checks', () => {
  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecksFixture)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')
  })

  describe('Mint', () => {
    it('Should allow to mint originals', async () => {
      const { checksEditions, checks, jalil } = await loadFixture(deployChecksFixture)

      await expect(checks.connect(jalil).mint([1001]))
        .to.be.revertedWith('Edition burn not approved')

      // Approve
      await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

      await expect(checks.connect(jalil).mint([1001]))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 1001)

      await expect(checks.connect(jalil).mint([44, 222]))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 44)
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 222)
    })

    it('Should allow to mint many originals at once', async () => {
      const { checksEditions, checks, vv } = await loadFixture(deployChecksFixture)

      await checksEditions.connect(vv).setApprovalForAll(checks.address, true)

      await expect(checks.connect(vv).mint(VV_TOKENS))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, VV, 9696)
    })
  })

  describe('Compositing', () => {
    it('Should allow to composite originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      await composite(VV_TOKENS.slice(0, 64), checks, vv, 0, false)
    })

    it.skip('Should composite and render originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      await composite(VV_TOKENS.slice(0, 64), checks, vv)
    })
  })
})
