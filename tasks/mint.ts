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
    await checks.connect(vv).mint(VV_TOKENS)

    console.log(`Minted all ${VV_TOKENS.length} Checks Originals`)
  })
