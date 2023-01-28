export const deployChecksWithLibraries = async (ethers) => {
  const Utils = await ethers.getContractFactory('Utils')
  const utils = await Utils.deploy()
  await utils.deployed()
  console.log(`     Deployed Utils at ${utils.address}`)

  const EightyColors = await ethers.getContractFactory('EightyColors')
  const eightyColors = await EightyColors.deploy()
  await eightyColors.deployed()
  console.log(`     Deployed EightyColors at ${eightyColors.address}`)

  const ChecksArt = await ethers.getContractFactory('ChecksArt', {
    libraries: {
      Utils: utils.address,
      EightyColors: eightyColors.address,
    }
  })
  const checksArt = await ChecksArt.deploy()
  await checksArt.deployed()
  console.log(`     Deployed ChecksArt at ${checksArt.address}`)

  const ChecksMetadata = await ethers.getContractFactory('ChecksMetadata', {
    libraries: {
      Utils: utils.address,
      ChecksArt: checksArt.address,
    }
  })
  const checksMetadata = await ChecksMetadata.deploy()
  await checksMetadata.deployed()
  console.log(`     Deployed ChecksMetadata at ${checksMetadata.address}`)

  const ChecksOriginals = await ethers.getContractFactory('Checks', {
    libraries: {
      Utils: utils.address,
      ChecksArt: checksArt.address,
      ChecksMetadata: checksMetadata.address,
    }
  })
  const checks = await ChecksOriginals.deploy()
  await checks.deployed()
  console.log(`     Deployed ChecksOriginals at ${checks.address}`)

  return {
    checks
  }
}
