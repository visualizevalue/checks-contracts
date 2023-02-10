import { mine } from '@nomicfoundation/hardhat-network-helpers'
import { Wallet } from 'ethers'
import { task } from 'hardhat/config'
import { EDITIONS, VV, VV_TOKENS } from '../helpers/constants'
import { impersonate } from '../helpers/impersonate'

task('mint-testing', 'Mint VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .setAction(async ({ contract }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)
    const checkEditions = await hre.ethers.getContractAt('ZoraEdition', EDITIONS)

    console.log(`Checks are at ${checks.address}`)

    const vv = await impersonate(VV, hre)

    // Approve
    await checkEditions.connect(vv).setApprovalForAll(checks.address, true)

    // Mint all
    await checks.connect(vv).mint(VV_TOKENS, VV)

    await mine(50)
    await (await checks.resolveEpochIfNecessary()).wait()

    console.log(`Minted all ${VV_TOKENS.length} Checks Originals`)
  })

task('mint-live', 'Mint original checks tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('from', 'The min token ID (inclusive)')
  .addParam('to', 'The max token ID (inclusive)')
  .setAction(async ({ contract, from, to }, hre) => {
    const signer = new Wallet(process.env.SIGNER_PK || '', hre.ethers.provider)
    const checks = await hre.ethers.getContractAt('Checks', contract)

    const tokens = [...Array(parseInt(to) - parseInt(from) + 1).keys()].map(t => t + parseInt(from))

    for (let i = 0; i < tokens.length; i+=100) {
      const ids = tokens.slice(i, i + 100)
      const tx = await checks.connect(signer).mint(ids, signer.address, {
        gasLimit: 20_000_000,
      })
      console.log(`Minted original check ${tokens[i]} - ${tokens[i + 100 - 1]}`)

      if (i > 0 && i % 500 === 0) {
        console.log(`Waiting for tx batch`)
        await tx.wait()
      }
    }
  })

task('reveal', 'Reveal tokens')
  .addParam('contract', 'Checks contract address')
  .setAction(async ({ contract }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)
    const vv = await impersonate(VV, hre)
    // Approve
    await checks.connect(vv).resolveEpochIfNecessary()
  })
