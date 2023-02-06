import { EDITIONS } from '../../helpers/constants';
import { deployChecksWithLibraries } from '../../helpers/deploy'
import { ethers } from 'hardhat';

export async function deployChecksMainnet() {
  const checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

  const { checks } = await deployChecksWithLibraries(ethers)

  return {
    checks,
    checksEditions,
  }
}

export async function deployChecks() {
  const checksEditions = await (await ethers.getContractFactory('ZoraEdition')).deploy()
  await checksEditions.deployed()

  const { checks } = await deployChecksWithLibraries(ethers, checksEditions.address)

  return {
    checks,
    checksEditions,
  }
}
