import fs from 'fs'
import { Contract } from 'ethers'

export const render = async (
  id: number,
  checksCount: number,
  contract: Contract
) => {
  fs.writeFileSync(`test/dist/${checksCount}_${id}.svg`, await contract.svg(id))
  console.log(`Saved #${id} with ${checksCount} checks`)
}

export const fetchAndRender = async (
  id: number,
  contract: Contract,
) => {
  const check = await contract.getCheck(id)
  const i = check.divisorIndex

  fs.writeFileSync(
    `test/dist/${check.checksCount}_${id}_b${check.colorBand[i]}_g${check.gradient[i]}_s${check.speed}.svg`,
    await contract.svg(id)
  )
  console.log(`Saved #${id} with ${check.checksCount} checks`)
}