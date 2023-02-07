import { task } from 'hardhat/config'
import { VV_TOKENS } from '../helpers/constants'
import { fetchAndRender, fetchAndRenderPreview } from '../helpers/render'

task('render-preview', 'Composite VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addParam('keep', 'The Check to keep')
  .addParam('burn', 'The Check to burn')
  .setAction(async ({ contract, keep, burn }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)

    await fetchAndRenderPreview(keep, burn, checks)
  })

task('render', 'Mint VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addOptionalParam('id', 'Which token ID to render')
  .setAction(async ({ contract, id }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)

    // console.log(await checks.getEpochData(1))
    // console.log(await checks.getCheck(VV_TOKENS[0]))

    if (id) {
      await fetchAndRender(id, checks)
    } else {
      for (const id of VV_TOKENS) {
        await fetchAndRender(id, checks)
      }
    }
  })
