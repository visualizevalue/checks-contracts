import { loadFixture } from 'ethereum-waffle'
import { Contract, Signer} from 'ethers'
import { parseEther } from 'ethers/lib/utils'
const { expect } = require('chai')
const hre = require('hardhat')
const ethers = hre.ethers

const EDITIONS = '0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9'
const VV = '0xc8f8e2F59Dd95fF67c3d39109ecA2e2A017D4c8a'
const JALIL = '0xe11Da9560b51f8918295edC5ab9c0a90E9ADa20B'

describe('Checks', () => {
  async function deployChecksFixture() {
    let ChecksOriginals,
        checks: Contract,
        checksEditions: Contract,
        vv: Signer,
        jalil: Signer;

    ChecksOriginals = await ethers.getContractFactory('Checks')
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

    // Fund me :kek:
    await vv.sendTransaction({ to: JALIL, value: parseEther('10') })

    return {
      checks,
      checksEditions,
      vv,
      jalil
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
    })
  })
})
