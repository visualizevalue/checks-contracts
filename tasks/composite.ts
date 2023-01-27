import { task } from 'hardhat/config'
import { composite } from '../helpers/composite'
import { VV, VV_TOKENS } from '../helpers/constants'
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

task('composite-tree', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .setAction(async ({ contract, keep, burn }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)
    const vv = await impersonate(VV, hre)

    const [singleId] = await composite(VV_TOKENS.slice(0, 64), checks, vv, 0, false)
    console.log('composited', singleId)
    console.log(await checks.getCheck(singleId))
  })
