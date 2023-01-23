import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { VV_TOKENS } from '../helpers/constants'
import { deployChecksFixture } from './deploy'

export async function mintedFixture() {
  const { checksEditions, checks, jalil, vv } = await await loadFixture(deployChecksFixture)

  await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
  await checks.connect(jalil).mint([
    808, 1444, 1750, 1909, 1967, 2244, 2567, 3325
  ])

  await checksEditions.connect(vv).setApprovalForAll(checks.address, true)
  await checks.connect(vv).mint(VV_TOKENS)

  return {
    checks,
    jalil,
    vv
  }
}
