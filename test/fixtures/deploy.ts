import { EDITIONS } from '../../helpers/constants';
import { deployChecksWithLibraries } from '../../helpers/deploy'
import { ethers } from 'hardhat';

export async function deployChecks() {
  const checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

  const { checks } = await deployChecksWithLibraries(ethers)

  return {
    checks,
    checksEditions,
  }
}
