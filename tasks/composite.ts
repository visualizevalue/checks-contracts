import { task } from 'hardhat/config'
import { VV } from '../helpers/constants'
import { impersonate } from '../helpers/impersonate'

task('composite', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('keep', 'The Check to keep')
  .addParam('burn', 'The Check to burn')
  .setAction(async ({ contract, keep, burn }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)
    const vv = await impersonate(VV, hre)

    await checks.connect(vv).composite(keep, burn)

    console.log(await checks.getCheck(keep))
  })
