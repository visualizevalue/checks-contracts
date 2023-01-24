import { parseEther } from 'ethers/lib/utils'
import { JALIL, VV, WHALE } from '../../helpers/constants'
import { impersonate } from '../../helpers/impersonate'
const hre = require('hardhat')

export async function impersonateAccounts() {
  const vv = await impersonate(VV, hre)
  const jalil = await impersonate(JALIL, hre)
  const whale = await impersonate(WHALE, hre)

  // Fund me :kek:
  await vv.sendTransaction({ to: JALIL, value: parseEther('1') })

  return {
    vv,
    jalil,
    whale,
  }
}
