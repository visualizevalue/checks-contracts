import { Wallet } from 'ethers'
import { task } from 'hardhat/config'
import { composite } from '../helpers/composite'
import { VV, VV_TOKENS } from '../helpers/constants'
import { impersonate } from '../helpers/impersonate'

task('composite-preview', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('keep', 'The Check to keep')
  .addParam('burn', 'The Check to burn')
  .setAction(async ({ contract, keep, burn }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)

    console.log(await checks.simulateComposite(keep, burn))
  })

task('composite', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('keep', 'The Check to keep')
  .addParam('burn', 'The Check to burn')
  .addOptionalParam('swap', 'The Check to burn')
  .setAction(async ({ contract, keep, burn, swap = false }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)
    const vv = await impersonate(VV, hre)

    await checks.connect(vv).composite(keep, burn, swap === 'true')

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

task('composite-live', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('from', 'The min token ID (inclusive)')
  .addParam('to', 'The max token ID (inclusive)')
  .setAction(async ({ contract, from, to }, hre) => {
    const signer = new Wallet(process.env.SIGNER_PK || '', hre.ethers.provider)
    const checks = await hre.ethers.getContractAt('Checks', contract)

    const singles = []
    const tokens = [...Array(parseInt(to) - parseInt(from) + 1).keys()].map(t => t + parseInt(from))
    const count = tokens.length

    let composited = 0
    while (composited < count - 64) {
      const [single] = await composite(tokens.slice(composited, composited + 64), checks, signer)
      console.log(`      Composited single check #${single}`)
      singles.push(single)
      composited += 64
    }

    console.log(`      Single tokens: ${JSON.stringify(singles)}`)
  })
