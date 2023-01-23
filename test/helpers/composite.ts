import fs from 'fs'
import { Contract, Signer } from 'ethers'
import { DIVISORS } from './constants'

export const composite = async (
  tokens: number[],
  checks: Contract,
  signer: Signer,
  divisorIndex: number = 0,
  save: boolean = true,
) => {
  const divisor = DIVISORS[divisorIndex]

  const toKeep = []
  const toBurn = []
  for (const [index, id] of tokens.entries()) {
    if (divisorIndex > -1 && save) {
      fs.writeFileSync(`test/dist/${id}_${divisor}.svg`, await checks.svg(id))
      console.log(`Saved ${id}@${divisor}`)
    }

    if (index % 2 == 0) {
      toKeep.push(tokens[index])
    } else {
      toBurn.push(tokens[index])
    }
  }

  await checks.connect(signer).compositeMany(toKeep, toBurn)
  // console.log(`Composited `, toKeep, toBurn)

  if (toKeep.length > 1 && divisor > 0) {
    composite(toKeep, checks, signer, divisorIndex + 1, save)
  } else if (save) {
    const id = toKeep[0]
    const divisor = DIVISORS[divisorIndex + 1]
    fs.writeFileSync(`test/dist/${id}_${divisor}.svg`, await checks.svg(id))
    console.log(`Saved ${id}@${divisor}`)
  }
}
