export const deployChecksWithLibraries = async (ethers) => {
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

  return {
    checks
  }
}
