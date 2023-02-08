import { loadFixture, mine } from '@nomicfoundation/hardhat-network-helpers'
import { parseEther } from 'ethers/lib/utils'
import { JACK, JALIL, JALIL_TOKENS, TOP_HOLDERS, VV, VV_TOKENS } from '../../helpers/constants'
import { impersonate } from '../../helpers/impersonate'
import { deployChecksMainnet } from './deploy'
import { impersonateAccounts } from './impersonate'
import hre from 'hardhat'
import { composite } from '../../helpers/composite'

export async function mintedFixture() {
  const { checksEditions, checks } = await loadFixture(deployChecksMainnet)
  const { jalil, vv } = await loadFixture(impersonateAccounts)

  await checksEditions.connect(jalil).setApprovalForAll(checks.address, true)
  await checks.connect(jalil).mint(JALIL_TOKENS, JALIL)

  await checksEditions.connect(vv).setApprovalForAll(checks.address, true)
  await checks.connect(vv).mint(VV_TOKENS, VV)

  await mine(50)
  await (await checks.resolveEpochIfNecessary()).wait()

  return {
    checks,
    jalil,
    vv
  }
}

export async function prepareBlackCheckFixture() {
  const { checksEditions, checks } = await loadFixture(deployChecksMainnet)
  const jack = await impersonate(JACK, hre)

  const allTokens = []

  for (const [holder, tokens] of Object.entries(TOP_HOLDERS)) {
    const signer = await impersonate(holder, hre)
    await jack.sendTransaction({ to: signer.address, value: parseEther('5') })

    await checksEditions.connect(signer).setApprovalForAll(checks.address, true)

    for (let i = 0; i < tokens.length; i+=100) {
      await checks.connect(signer).mint(tokens.slice(i, i + 100), signer.address)
    }

    for (const id of tokens) {
      if (signer.address.toLowerCase() !== VV.toLowerCase()) {
        await checks.connect(signer).transferFrom(signer.address, VV, id)
      }
      allTokens.push(id)
    }
    console.log(`      Transferred ${tokens.length} checks to VV (totalling ${allTokens.length})`)
  }

  return {
    checks,
    jack,
    allTokens,
  }
}

export async function blackCheckFixture() {
  const { allTokens, checks } = await loadFixture(prepareBlackCheckFixture)
  const vv = await impersonate(VV, hre)

  const singles = []

  for (let i = 0; i < 4096; i+=64) {
    const [single] = await composite(allTokens.slice(i, i + 64), checks, vv)
    // // Uncomment below to render each single check
    // await fetchAndRender(single, checks)
    console.log(`      Composited single check ${i / 64 + 1} (#${single})`)
    singles.push(single)
  }

  await checks.connect(vv).infinity(singles)

  return {
    singles,
    blackCheck: singles[0],
    vv,
    checks,
    allTokens,
  }
}
