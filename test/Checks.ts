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

const VV_TOKENS = [
  10115, 10193, 10194, 1060, 11176, 11177, 11323, 11505, 11545, 1164, 11828, 12028, 12076,
  12163, 12175, 12459, 13052, 13075, 13124, 13359, 13677, 13705, 13948, 13959, 14114, 14686,
  14693, 14806, 14808, 14810, 14937, 15091, 15114, 1534, 15488, 15556, 15594, 15811, 1587,
  1855, 1866, 1964, 2026, 2397, 2529, 2657, 2668, 2732, 2733, 3020, 3096, 3108, 3329, 3330,
  3331, 3364, 3694, 3710, 3723, 3732, 3737, 3738, 3752, 3755, 4047, 4133, 4408, 4547, 4552,
  4809, 4911, 5517, 5775, 6012, 6013, 6014, 6015, 6016, 6017, 6018, 6019, 6020, 6381, 6405,
  6406, 6421, 6447, 645, 6458, 6459, 6460, 6518, 6735, 6737, 6831, 6978, 6980, 7582, 7583,
  7584, 7585, 7586, 7587, 7588, 7589, 7590, 7591, 7592, 7593, 7594, 7595, 7596, 7597, 7598,
  7599, 7601, 7602, 7603, 7604, 7605, 7606, 7609, 7610, 9294, 9306, 9470, 9696
]

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

    checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

    Utils = await ethers.getContractFactory('Utils')
    utils = await Utils.deploy()
    await utils.deployed()

    ChecksArt = await ethers.getContractFactory('ChecksArt', {
      libraries: {
        Utils: utils.address,
      }
    })
    checksArt = await ChecksArt.deploy()
    await checksArt.deployed()

    ChecksOriginals = await ethers.getContractFactory('Checks', {
      libraries: {
        Utils: utils.address,
        ChecksArt: checksArt.address,
      }
    })
    checks = await ChecksOriginals.deploy()
    await checks.deployed()

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
      jalil,
      whale,
    }
  }

  async function mintedFixture() {
    const { checksEditions, checks, jalil, vv } = await deployChecksFixture()

    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
    await checks.connect(jalil).mint([
      808, 1444, 1750, 1909, 1967, 2244, 2567, 3325
    ])

    await checksEditions.connect(vv).setApprovalForAll(checks.address, true)
    await checks.connect(vv).mint(VV_TOKENS)

    return {
      checks,
      jalil,
      vv
    }
  }

  it('Should deploy checks', async () => {
    const { checks } = await loadFixture(deployChecksFixture)

    expect(await checks.editionChecks()).to.equal('0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9')
  })

  describe('Mint', () => {
    it.skip('Should allow to mint originals', async () => {
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

    it.skip('Should allow to mint many originals at once', async () => {
      const { checksEditions, checks, vv } = await loadFixture(deployChecksFixture)

      await checksEditions.connect(vv).setApprovalForAll(checks.address, true)

      await expect(checks.connect(vv).mint(VV_TOKENS))
        .to.emit(checks, 'Transfer')
        .withArgs(ethers.constants.AddressZero, VV, 9696)
    })
  })

  describe('Compositing', () => {
    let DIVISORS = [80, 40, 20, 10, 5, 4, 1, 0]

    const composite = async (
      tokens: number[],
      checks: Contract,
      signer: Signer,
      divisorIndex: number = 0
    ) => {
      const divisor = DIVISORS[divisorIndex]

      const toKeep = []
      const toBurn = []
      for (const [index, id] of tokens.entries()) {
        if (divisorIndex > 1) {
          fs.writeFileSync(`test/dist/${id}_${divisor}.svg`, await checks.svg(id))
          console.log(`Saved ${id}@${divisor}`)
        }

        if (index % 2 == 0) {
          toKeep.push(tokens[index])
        } else {
          toBurn.push(tokens[index])
        }
      }

      await checks.connect(signer).compositeMany(toKeep, toBurn)
      console.log(`Composited `, toKeep, toBurn)

      if (toKeep.length > 1 && divisor > 0) {
        composite(toKeep, checks, signer, divisorIndex + 1)
      } else {
        const id = toKeep[0]
        const divisor = DIVISORS[divisorIndex + 1]
        fs.writeFileSync(`test/dist/${id}_${divisor}.svg`, await checks.svg(id))
        console.log(`Saved ${id}@${divisor}`)
      }
    }


    it.skip('Should allow to composite originals', async () => {
      const { checks, vv } = await loadFixture(mintedFixture)

      await composite(VV_TOKENS.slice(0, 64), checks, vv)
    })
  })
})
