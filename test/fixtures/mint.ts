import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { JALIL_TOKENS, VV_TOKENS } from '../../helpers/constants'
import { deployChecks } from './deploy'
import { impersonateAccounts } from './impersonate'

export async function mintedFixture() {
  const { checksEditions, checks } = await loadFixture(deployChecks)
  const { jalil, vv } = await loadFixture(impersonateAccounts)

  await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
  await checks.connect(jalil).mint(JALIL_TOKENS)

  await checksEditions.connect(vv).setApprovalForAll(checks.address, true)
  await checks.connect(vv).mint(VV_TOKENS)

  return {
    checks,
    jalil,
    vv
  }
}
