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
  prepend: string = '',
) => {
  const check = await contract.getCheck(id)

  fs.writeFileSync(
    `test/dist/${prepend}${check.checksCount}_${id}_b${check.colorBand}_g${check.gradient}_s${check.speed}_d${check.direction}.svg`,
    await contract.svg(id)
  )
}

export const fetchAndRenderPreview = async (
  id: number,
  burn: number,
  contract: Contract,
) => {
  const check = await contract.simulateComposite(id, burn)

  fs.writeFileSync(
    `test/dist/${check.checksCount}_${id}_b${check.colorBand}_g${check.gradient}_s${check.speed}_d${check.direction}_preview.svg`,
    await contract.simulateCompositeSVG(id, burn)
  )
}
