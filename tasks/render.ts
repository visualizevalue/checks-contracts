import { task } from 'hardhat/config'
import { VV_TOKENS } from '../helpers/constants'
import { fetchAndRender } from '../helpers/render'

task('render', 'Mint VV tokens')
  .addParam('contract', 'The Checks Contract address')
  .addOptionalParam('id', 'Which token ID to render')
  .setAction(async ({ contract, id }, hre) => {
    const checks = await hre.ethers.getContractAt('Checks', contract)

    if (id) {
      await fetchAndRender(id, checks)
    } else {
      for (const id of VV_TOKENS) {
        await fetchAndRender(id, checks)
      }
    }
  })
