import { Contract, Signer } from 'ethers'
import { DIVISORS } from '../helpers/constants'
import { render } from '../helpers/render'

export const composite = async (
  tokens: number[],
  checks: Contract,
  signer: Signer,
  divisorIndex: number = 0,
  save: boolean = false,
): Promise<[id: number, divisor: number]> => {
  const divisor = DIVISORS[divisorIndex]

  const toKeep = []
  const toBurn = []
  for (const [index, id] of tokens.entries()) {
    if (save) await render(id, divisor, checks)

    if (index % 2 == 0) {
      toKeep.push(tokens[index])
    } else {
      toBurn.push(tokens[index])
    }
  }

  try {
    const tx = await checks.connect(signer).compositeMany(toKeep, toBurn, {
      gasLimit: (await checks.connect(signer).estimateGas.compositeMany(toKeep, toBurn)).mul(2)
    })

    if (toKeep.length == 1) {
      // console.log(`      Waiting for current batch of tx...`)
      await tx.wait()
    }
  } catch (e) {
    console.log(e.reason || 'fail')
  }

  if (toKeep.length > 1 && divisor > 0) {
    return composite(toKeep, checks, signer, divisorIndex + 1, save)
  }

  const id = toKeep[0]
  const finalDivisor = DIVISORS[divisorIndex + 1]
  if (save) await render(id, finalDivisor, checks)

  return [id, finalDivisor]
}
