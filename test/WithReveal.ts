import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
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

  it('Should mint tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecks)

    await checksEditions.setApprovalForAll(checks.address, true);

    await checksEditions.mintAmount(4)

    await checks.mint([1,2,3,4], signers[0].address)

    const beforeReveal = await checks.getCheck(1)
    expect(beforeReveal.isRevealed).to.equal(false)

    await hre.network.provider.send("hardhat_mine", ["0x5"])
    await (await checks.nextEpoch()).wait()

    const afterReveal = await checks.getCheck(1)
    expect(afterReveal.isRevealed).to.equal(true)
  })
})
