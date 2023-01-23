import { Contract, Signer} from 'ethers'
import { parseEther } from 'ethers/lib/utils'
import { EDITIONS, JALIL, VV, WHALE } from '../helpers/constants';
const hre = require('hardhat')
const ethers = hre.ethers

export async function deployChecksFixture() {
  let
      EightyColors,
      eightyColors,
      ChecksArt,
      checksArt,
      Utils,
      utils,
      ChecksOriginals,
      checks: Contract,
      checksEditions: Contract,
      vv: Signer,
      jalil: Signer,
      whale: Signer;

  checksEditions = await ethers.getContractAt('ZoraEdition', EDITIONS)

  Utils = await ethers.getContractFactory('Utils')
  utils = await Utils.deploy()
  await utils.deployed()

  EightyColors = await ethers.getContractFactory('EightyColors')
  eightyColors = await EightyColors.deploy()
  await eightyColors.deployed()

  ChecksArt = await ethers.getContractFactory('ChecksArt', {
    libraries: {
      Utils: utils.address,
      EightyColors: eightyColors.address,
    }
  })
  checksArt = await ChecksArt.deploy()
  await checksArt.deployed()

  ChecksOriginals = await ethers.getContractFactory('Checks', {
    libraries: {
      Utils: utils.address,
      ChecksArt: checksArt.address,
    }
  })
  checks = await ChecksOriginals.deploy()
  await checks.deployed()

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [VV],
  })
  vv = await ethers.getSigner(VV)

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [JALIL],
  })
  jalil = await ethers.getSigner(JALIL)

  await hre.network.provider.request({
    method: 'hardhat_impersonateAccount',
    params: [WHALE],
  })
  whale = await ethers.getSigner(WHALE)

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
