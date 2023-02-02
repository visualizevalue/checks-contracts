import fs from 'fs'
import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { deployChecks } from './fixtures/deploy'
import { impersonateAccounts } from './fixtures/impersonate'
import { blackCheckFixture, mintedFixture } from './fixtures/mint'
import { composite } from '../helpers/composite'
import { JALIL, JALIL_TOKENS, JALIL_VAULT, VV, VV_TOKENS } from '../helpers/constants'
import { fetchAndRender } from '../helpers/render'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

describe('Checks', () => {
  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecks)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')

    expect(await checks.name()).to.equal('Checks')
    expect(await checks.symbol()).to.equal('CHECKS')
  })

  describe.only('Mint', () => {
    // TODO: Write test for approved hot wallet mint
    it('Should allow to mint originals', async () => {
      const { checksEditions, checks } = await loadFixture(deployChecks)
      const { jalil } = await loadFixture(impersonateAccounts)

      expect(await checks.totalSupply()).to.equal(0)

      await expect(checks.connect(jalil).mint([1001], JALIL_VAULT))
        .to.be.revertedWithCustomError(checksEditions, 'TransferCallerNotOwnerNorApproved')

      // First we need to approve the Originals contract on the Editions contract
      await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

      // Then we can mint one
      await expect(checks.connect(jalil).mint([1001], JALIL_VAULT))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 1001)
        .to.emit(checks, 'Transfer')
        .withArgs(JALIL, JALIL_VAULT, 1001)

      expect(await checks.totalSupply()).to.equal(1)

      // Or multiple
      await expect(checks.connect(jalil).mint([44, 222], JALIL_VAULT))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 44)
        .to.emit(checks, 'Transfer')
        .withArgs(JALIL, JALIL_TOKENS, 44)
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, JALIL, 222)
        .to.emit(checks, 'Transfer')
        .withArgs(JALIL, JALIL_VAULT, 222)

      expect(await checks.totalSupply()).to.equal(3)
    })

    it('Should allow to mint many originals at once', async () => {
      const { checksEditions, checks } = await loadFixture(deployChecks)
      const { vv } = await loadFixture(impersonateAccounts)

      await checksEditions.connect(vv).setApprovalForAll(checks.address, true)

      await expect(checks.connect(vv).mint(VV_TOKENS, JALIL_VAULT))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, VV, 9696)
        .to.emit(checks, 'Transfer')
        .withArgs(VV, JALIL_VAULT, 9696)
    })
  })

  describe('Burning', () => {
    it('Should not allow non approved operators to burn tokens', async () => {
      const { checks } = await loadFixture(mintedFixture)

      await expect(checks.burn(VV_TOKENS[0]))
        .to.be.revertedWith('ERC721: caller is not token owner or approved')
    })

    it('Should allow holders to burn their tokens', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const id = VV_TOKENS[0]

      await expect(checks.connect(vv).burn(id))
        .to.emit(checks, 'Transfer')
        .withArgs(vv.address, ethers.constants.AddressZero, id)
    })

    it('Should properly track total supply when users burn burn their tokens', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      expect(await checks.totalSupply()).to.equal(134)
      await checks.connect(vv).burn(VV_TOKENS[0])
      expect(await checks.totalSupply()).to.equal(133)
    })
  })

  describe('Swapping', () => {
    it('Should not allow people to swap tokens of other users', async () => {
      const { checks } = await loadFixture(mintedFixture)

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await expect(checks.inItForTheArt(toKeep, toBurn))
        .to.be.revertedWith('Not the owner or approved')
    })

    it('Should allow people to swap their own tokens', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      // TODO: Check metadata / svg and ensure it's the same...

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await expect(checks.connect(vv).inItForTheArt(toKeep, toBurn))
        .to.emit(checks, 'Sacrifice')
        .withArgs(toBurn, toKeep)
    })

    it('Should allow people to swap approved tokens', async () => {
      const { checks, vv, jalil } = await loadFixture(mintedFixture)
      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)

      await expect(checks.connect(jalil).inItForTheArt(toKeep, toBurn))
        .to.be.reverted

      await checks.connect(vv).setApprovalForAll(jalil.address, true)

      await expect(checks.connect(jalil).inItForTheArt(toKeep, toBurn))
        .to.emit(checks, 'Sacrifice')
        .withArgs(toBurn, toKeep)
    })

    it('Should allow people to swap multiple tokens at once', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const toKeep = VV_TOKENS.slice(0, 3)
      const toBurn = VV_TOKENS.slice(3, 6)
      await expect(checks.connect(vv).inItForTheArts(toKeep, toBurn))
        .to.emit(checks, 'Sacrifice')
        .withArgs(toBurn[0], toKeep[0])
        .to.emit(checks, 'Sacrifice')
        .withArgs(toBurn[1], toKeep[1])
        .to.emit(checks, 'Sacrifice')
        .withArgs(toBurn[2], toKeep[2])
    })
  })

  describe('Compositing', () => {
    it('Should not allow people to composit tokens of other users', async () => {
      const { checks } = await loadFixture(mintedFixture)

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await expect(checks.composite(toKeep, toBurn))
        .to.be.revertedWith('Not the owner or approved')
    })

    it('Should allow people to swap approved tokens', async () => {
      const { checks, vv, jalil } = await loadFixture(mintedFixture)
      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)

      await expect(checks.connect(jalil).composite(toKeep, toBurn))
        .to.be.reverted

      await checks.connect(vv).setApprovalForAll(jalil.address, true)

      await expect(checks.connect(jalil).composite(toKeep, toBurn))
        .to.emit(checks, 'Composite')
        .withArgs(toKeep, toBurn, 40)
    })

    it('Should allow to composite originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      expect(await checks.totalSupply()).to.equal(134)

      const [toKeep, toBurn] = VV_TOKENS.slice(0, 2)
      await checks.connect(vv).composite(toKeep, toBurn)

      expect(await checks.totalSupply()).to.equal(133)

      const check = await checks.getCheck(toKeep)

      expect(check.composite).to.equal(toBurn)
      expect(check.checksCount).to.equal(40)
      expect(check.stored.divisorIndex).to.equal(1)
    })

    it('Should allow to composite many originals at once', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const totalSupply = await checks.totalSupply()
      expect(totalSupply).to.equal(134)

      await composite(VV_TOKENS.slice(0, 64), checks, vv)

      expect(await checks.totalSupply()).to.equal(totalSupply - 63) // One survives
    })

    it('Should allow to composite and render many originals', async () => {
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

      await fetchAndRender(JALIL_TOKENS[0], checks)
    })

    it.skip('Should allow to composite to, mint, and render the black check', async () => {
      const { checks, blackCheck, allTokens } = await loadFixture(blackCheckFixture)

      console.log(`      Created the first black check with ID #${blackCheck}`)
      await fetchAndRender(blackCheck, checks)
      console.log(`      Rendered the first black check`)
      fs.writeFileSync(`test/dist/tokenuri-${blackCheck}`, await checks.tokenURI(blackCheck))
      console.log(`      Saved black check metadata`)

      expect(await checks.totalSupply()).to.equal(allTokens.length - 64 * 64 + 1)
    })
  })

  describe('Metadata', () => {
    it('Should show correct metadata', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      const uri = await checks.tokenURI(VV_TOKENS[0])
      fs.writeFileSync(`test/dist/tokenuri-${VV_TOKENS[0]}`, uri)

      const uri2 = await checks.tokenURI(VV_TOKENS[1])
      fs.writeFileSync(`test/dist/tokenuri-${VV_TOKENS[1]}`, uri2)

      const [singleId] = await composite(VV_TOKENS.slice(2, 66), checks, vv, 0, false)
      fs.writeFileSync(`test/dist/tokenuri-${singleId}`, await checks.tokenURI(singleId))
    })
  })
})
