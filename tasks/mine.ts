import { mine } from '@nomicfoundation/hardhat-network-helpers'
import { task } from "hardhat/config"

task('mine', 'Mines an arbitrary amount of blocks')
  .addParam('blocks', 'How many blocks to mine')
  .setAction(async ({ blocks }) => {
    await mine(parseInt(blocks))
  })
