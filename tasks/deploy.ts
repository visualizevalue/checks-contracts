import { task } from 'hardhat/config'
import { deployChecksWithLibraries } from '../helpers/deploy'

task('deploy', 'Deploys all contracts for testing', async (_, hre) => {
  const { checks } = await deployChecksWithLibraries(hre.ethers)

  console.log(`Successfully deployed Checks at ${checks.address}`)
})
