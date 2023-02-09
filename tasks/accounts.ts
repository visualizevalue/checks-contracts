import { parseEther } from "ethers/lib/utils";
import { task } from "hardhat/config";
import { JALIL, VV } from "../helpers/constants";
import { impersonate } from "../helpers/impersonate";

task('accounts', 'Prints the list of accounts', async (_, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

task('fund-jalil', 'Funds jalil for testing', async (_, hre) => {
  const vv = await impersonate(VV, hre)
  const jalil = await impersonate(JALIL, hre)

  // Fund me :kek:
  await vv.sendTransaction({ to: JALIL, value: parseEther('1') })
})
