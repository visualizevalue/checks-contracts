import { parseEther } from 'ethers/lib/utils'
import { EDITIONS, JALIL, VV, WHALE } from '../helpers/constants';
const hre = require('hardhat')
const ethers = hre.ethers

export async function deployChecksFixture() {
  const checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

  const Utils = await ethers.getContractFactory('Utils')
  const utils = await Utils.deploy()
  await utils.deployed()

  const EightyColors = await ethers.getContractFactory('EightyColors')
  const eightyColors = await EightyColors.deploy()
  await eightyColors.deployed()

  const ChecksArt = await ethers.getContractFactory('ChecksArt', {
    libraries: {
      Utils: utils.address,
      EightyColors: eightyColors.address,
    }
  })
  const checksArt = await ChecksArt.deploy()
  await checksArt.deployed()

  const ChecksMetadata = await ethers.getContractFactory('ChecksMetadata', {
    libraries: {
      ChecksArt: checksArt.address,
    }
  })
  const checksMetadata = await ChecksMetadata.deploy()
  await checksMetadata.deployed()

  const ChecksOriginals = await ethers.getContractFactory('Checks', {
    libraries: {
      Utils: utils.address,
      ChecksArt: checksArt.address,
      ChecksMetadata: checksMetadata.address,
    }
  })
  const checks = await ChecksOriginals.deploy()
  await checks.deployed()


  // Impersonate accounts

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [VV],
  })
  const vv = await ethers.getSigner(VV)

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [JALIL],
  })
  const jalil = await ethers.getSigner(JALIL)

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [WHALE],
  })
  const whale = await ethers.getSigner(WHALE)

  // Fund me :kek:
  await vv.sendTransaction({ to: JALIL, value: parseEther('1') })

  return {
    checks,
    checksEditions,
    vv,
    jalil,
    whale,
  }
}
