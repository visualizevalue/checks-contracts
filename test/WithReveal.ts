import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { deployChecksMainnet } from './fixtures/deploy'
import { impersonateAccounts } from './fixtures/impersonate'
const { expect } = require('chai')
const hre = require('hardhat')

describe('WithReveal', () => {
  it('Should mint unrevealed tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecksMainnet)
    const { jalil } = await loadFixture(impersonateAccounts)

    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
    await expect(checks.connect(jalil).mint([808], jalil.address))
      .not.to.emit(checks, 'NewEpoch')

    const beforeReveal = await checks.getCheck(808)
    expect(beforeReveal.isRevealed).to.equal(false)

    await mine(50)
    expect((await checks.getCheck(808)).isRevealed).to.equal(false)

    const firstEpoch = await checks.getEpochData(1)
    const secondEpoch = await checks.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(false)
    expect(secondEpoch.committed).to.equal(false)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and reveal tokens', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecksMainnet)
    const { jalil } = await loadFixture(impersonateAccounts)

    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
    await expect(checks.connect(jalil).mint([808], jalil.address))
      .not.to.emit(checks, 'NewEpoch')

    await mine(50)
    await expect(checks.resolveEpochIfNecessary())
      .to.emit(checks, 'NewEpoch')

    const afterReveal = await checks.getCheck(808)
    expect(afterReveal.isRevealed).to.equal(true)

    const firstEpoch = await checks.getEpochData(1)
    const secondEpoch = await checks.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should mint and auto-reveal tokens on new mints', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecksMainnet)
    const { jalil } = await loadFixture(impersonateAccounts)
    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

    const tx = await checks.connect(jalil).mint([808, 1444], jalil.address)
    await expect(tx).not.to.emit(checks, 'NewEpoch')
    await mine(50)

    const revealBlock = (await tx.wait()).blockNumber + 50

    await expect(checks.connect(jalil).mint([1750, 1909], jalil.address))
      .to.emit(checks, 'NewEpoch')
      .withArgs(1, revealBlock)
    expect((await checks.getCheck(808)).isRevealed).to.equal(true)
    expect((await checks.getCheck(1444)).isRevealed).to.equal(true)
    expect((await checks.getCheck(1750)).isRevealed).to.equal(false)
    expect((await checks.getCheck(1909)).isRevealed).to.equal(false)

    const firstEpoch = await checks.getEpochData(1)
    const secondEpoch = await checks.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should extend a previous commitment', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecksMainnet)
    const { jalil } = await loadFixture(impersonateAccounts)
    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

    await expect(checks.connect(jalil).mint([808], jalil.address))
      .not.to.emit(checks, 'NewEpoch')
    await mine(306)

    await expect(checks.connect(jalil).mint([1444], jalil.address))
      .not.to.emit(checks, 'NewEpoch')
    expect((await checks.getCheck(808)).isRevealed).to.equal(false)
    expect((await checks.getCheck(1444)).isRevealed).to.equal(false)

    await mine(50)
    await expect(checks.connect(jalil).mint([1750], jalil.address))
      .to.emit(checks, 'NewEpoch')

    expect((await checks.getCheck(808)).isRevealed).to.equal(true)
    expect((await checks.getCheck(1444)).isRevealed).to.equal(true)
    expect((await checks.getCheck(1750)).isRevealed).to.equal(false)

    const firstEpoch = await checks.getEpochData(1)
    const secondEpoch = await checks.getEpochData(2)
    expect(firstEpoch.committed).to.equal(true)
    expect(firstEpoch.revealed).to.equal(true)
    expect(secondEpoch.committed).to.equal(true)
    expect(secondEpoch.revealed).to.equal(false)
  })

  it('Should allow manually creating new epochs between mints', async () => {
    const { checks, checksEditions } = await loadFixture(deployChecksMainnet)
    const { jalil } = await loadFixture(impersonateAccounts)
    await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)

    await checks.connect(jalil).mint([808], jalil.address)
    expect(await checks.getEpoch()).to.equal(1)
    await mine(50)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect((await checks.getCheck(808)).isRevealed).to.equal(true)
    expect(await checks.getEpoch()).to.equal(2)
    await mine(50)
    await (await checks.resolveEpochIfNecessary()).wait()
    await (await checks.resolveEpochIfNecessary()).wait()
    await (await checks.resolveEpochIfNecessary()).wait()
    expect(await checks.getEpoch()).to.equal(3)
    await mine(50)
    await checks.connect(jalil).mint([1444], jalil.address)
    expect(await checks.getEpoch()).to.equal(4)
    await mine(50)
    expect(await checks.getEpoch()).to.equal(4)
    expect((await checks.getCheck(1444)).isRevealed).to.equal(false)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect((await checks.getCheck(1444)).isRevealed).to.equal(true)
    expect(await checks.getEpoch()).to.equal(5)
    await mine(306)
    await checks.connect(jalil).mint([1750], jalil.address)
    expect(await checks.getEpoch()).to.equal(5)
    await mine(3)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect((await checks.getCheck(1750)).isRevealed).to.equal(false)
    expect(await checks.getEpoch()).to.equal(5)
    await mine(50)
    await (await checks.resolveEpochIfNecessary()).wait()
    expect((await checks.getCheck(1750)).isRevealed).to.equal(true)
    expect(await checks.getEpoch()).to.equal(6)
    await mine(50)

    let epoch = await checks.getEpochData(1)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpochData(4)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpochData(5)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(true)
    epoch = await checks.getEpochData(6)
    expect(epoch.committed).to.equal(true)
    expect(epoch.revealed).to.equal(false)
  })
})
