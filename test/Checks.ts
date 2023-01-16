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
    let Utils,
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

    ChecksOriginals = await ethers.getContractFactory('Checks', {
      libraries: {
        Utils: utils.address,
      }
    })
    checks = await ChecksOriginals.deploy()
    await checks.deployed()

    checksEditions = await ethers.getContractAt('ERC721Burnable', EDITIONS)

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
      808, 1444,
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
      const [possibleColors, indexes] = await checks.colorIndexes(1001)
      console.log(1001, possibleColors, indexes.map(n => n.toNumber()))
    })
  })

  describe('Compositing', () => {
    it.only('Should allow to composite originals', async () => {
      const { checks, jalil } = await loadFixture(mintedFixture)

      const token = await checks.getCheck(808)
      console.log({
        checks: token.checks,
        level: token.level,
        composite: token.composite,
        seed: token.seed,
      })
      const [possibleColors, indexes] = await checks.colorIndexes(808)
      console.log(808, possibleColors, indexes.map(n => n.toNumber()))
      const colors = await checks.colors(808)
      console.log(colors)

      const token1444 = await checks.getCheck(1444)
      console.log({
        checks: token1444.checks,
        level: token1444.level,
        composite: token1444.composite,
        seed: token1444.seed,
      })
      const [possibleColors1444, indexes1444] = await checks.colorIndexes(1444)
      console.log(1444, possibleColors1444, indexes1444.map(n => n.toNumber()))
      const colors1444 = await checks.colors(1444)
      console.log(colors1444)

      await expect(checks.connect(jalil).composite(808, 1444))
        .to.emit(checks, 'Composite')
        .withArgs(808, 1444, 40)

      const token808_40 = await checks.getCheck(808)
      console.log({
        checks: token808_40.checks,
        level: token808_40.level,
        composite: token808_40.composite,
        seed: token808_40.seed,
      })
      const [possibleColors808_40, indexes808_40] = await checks.colorIndexes(808)
      console.log(808, possibleColors808_40, indexes808_40.map(n => n.toNumber()))

      // const colors808 = await checks.colors(808)
      // console.log(colors808)
    })
  })
})
