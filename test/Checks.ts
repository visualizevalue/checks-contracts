import fs from 'fs'
import { loadFixture } from 'ethereum-waffle'
import { BigNumber, Contract, Signer} from 'ethers'
import { parseEther } from 'ethers/lib/utils'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

const EDITIONS = '0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9'
const VV = '0xc8f8e2F59Dd95fF67c3d39109ecA2e2A017D4c8a'
const JALIL = '0xe11Da9560b51f8918295edC5ab9c0a90E9ADa20B'
const WHALE = '0x5efdB6D8c798c2c2Bea5b1961982a5944F92a5C1'

describe('Checks', () => {
  async function deployChecksFixture() {
    let
        ChecksArt,
        checksArt,
        Utils,
        utils,
        ChecksOriginals,
        checks: Contract,
        checksEditions: Contract,
        vv: Signer,
        jalil: Signer,
        whale: Signer;

    Utils = await ethers.getContractFactory('Utils')
    utils = await Utils.deploy()
    await utils.deployed()

    console.log('UTILS DEPLOYED', utils.address)

    ChecksArt = await ethers.getContractFactory('ChecksArt', {
      libraries: {
        Utils: utils.address,
      }
    })
    checksArt = await ChecksArt.deploy()
    await checksArt.deployed()

    console.log('CHECKSART DEPLOYED', checksArt.address)

    ChecksOriginals = await ethers.getContractFactory('Checks', {
      libraries: {
        Utils: utils.address,
        ChecksArt: checksArt.address,
      }
    })
    checks = await ChecksOriginals.deploy()
    await checks.deployed()

    console.log('CHECKS DEPLOYED')

    checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [VV],
    })
    vv = await ethers.getSigner(VV)

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [JALIL],
    })
    jalil = await ethers.getSigner(JALIL)

    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [WHALE],
    })
    whale = await ethers.getSigner(WHALE)

    // Fund me :kek:
    await vv.sendTransaction({ to: JALIL, value: parseEther('1') })

    return {
      checks,
      checksEditions,
      vv,
      jalil
    }
  }

  async function mintedFixture() {
    const { checksEditions, checks, jalil } = await deployChecksFixture()

    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
    await checks.connect(jalil).mint([
      808, 1444, 1750, 1909, 1967, 2244, 2567, 3325
      // 1304, 1444, 1750, 1909, 1967, 2244, 2567, 3325, 3378,
      // 3486, 4790, 5581, 6192, 9075, 12480, 14319, 14479, 15109, 15424,
    ])

    console.log('Minting fixture complete')

    return {
      checks,
      jalil,
    }
  }

  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecksFixture)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')
  })

  describe('Mint', () => {
    it('Should allow to mint originals', async () => {
      const { checksEditions, checks, jalil } = await loadFixture(deployChecksFixture)

      await expect(checks.connect(jalil).mint([1001]))
        .to.be.revertedWith('Edition burn not approved.')

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


      const token = await checks.getCheck(1001)
      console.log({
        checks: token.checks,
        level: token.level,
        composite: token.composite,
        seed: token.seed,
      })
      const indexes = await checks.colorIndexes(1001)
      console.log(1001, indexes.map(n => n.toNumber()))
    })
  })

  describe('Compositing', () => {
    it('Should allow to composite originals', async () => {
      const { checks, jalil } = await loadFixture(mintedFixture)

      expect(await checks.ownerOf(808)).to.equal(JALIL)
      console.log(await checks.ownerOf(808))
      console.log(await checks.ownerOf(808))

      const tokens = [808, 1444, 1750, 1909, 1967, 2244, 2567, 3325]

      for (const [index, id] of tokens.entries()) {
        const indexes = await checks.colorIndexes(id)
        console.log(id, indexes.map(n => n.toNumber()))

        console.log('hi', id)
        // fs.writeFileSync(`test/dist/${id}_80.svg`, await checks.svg(id))

        if (index % 2 == 0) {
          await checks.connect(jalil).composite(tokens[index], tokens[index + 1])

          const indexes = await checks.colorIndexes(id)
          console.log(id, indexes.map(n => n.toNumber()))

          fs.writeFileSync(`test/dist/${id}_40.svg`, await checks.svg(id))
        }
      }

      await checks.connect(jalil).composite(808, 1750)
      await checks.connect(jalil).composite(1967, 2567)

      let i = await checks.colorIndexes(808)
      console.log(808, i.map(n => n.toNumber()));

      i = await checks.colorIndexes(1967)
      console.log(1967, i.map(n => n.toNumber()))

      fs.writeFileSync('test/dist/808_20.svg', await checks.svg(808))
      fs.writeFileSync('test/dist/1967_20.svg', await checks.svg(1967))

      await checks.connect(jalil).composite(808, 1967);
      i = await checks.colorIndexes(808)
      console.log(808, i.map(n => n.toNumber()))
      console.log(await checks.colors(808))

      console.log(await checks.ownerOf(808))
      console.log(await checks.getCheck(808))
      const svg = await checks.svg(808)
      console.log(svg)
      fs.writeFileSync('test/dist/808_10.svg', svg)
    })

    it.only('Should render 40s correctly', async () => {
      const { checks, jalil } = await loadFixture(mintedFixture)

      const tokens = [808, 1444]

      for (const [index, id] of tokens.entries()) {
        if (index % 2 == 0) {
          await checks.connect(jalil).composite(tokens[index], tokens[index + 1])
          fs.writeFileSync(`test/dist/${id}_40.svg`, await checks.svg(id))
        }
      }
    })
  })
})
