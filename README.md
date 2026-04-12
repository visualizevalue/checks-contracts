# Checks

Checks is a fully on-chain generative art protocol on Ethereum that explores emergent value creation through participant-driven scarcity. Starting from 16,031 identical tokens, holders create differentiation through irreversible on-chain burning — verification earned through sacrifice, not authority.

Created by [Jack Butcher](https://x.com/jackbutcher) and [Jalil Wahdatehagh](https://x.com/jalilwahdat) at [Visualize Value](https://visualizevalue.com).

## How It Works

Checks began as **Editions** — 16,031 static, identical tokens. Holders burn their Edition to mint a dynamic **Original** with randomized visual properties (colors, gradients, animation). Originals can then be transformed through three core operations:

### Composite

Combines two tokens of equal check count by permanently burning one. The surviving token moves up a rarity tier:

```
80 → 40 → 20 → 10 → 5 → 4 → 1
```

When tokens composite, their colors _breed_ rather than simply transfer — creating new combinations while maintaining genetic lineage from both parents.

### Sacrifice

Burns one token to transfer its visual properties (colors, gradients) to another without changing its rarity tier. This enables aesthetic optimization independent of scarcity.

### Infinity

Exactly 64 single-check tokens can be combined to create a **Black Check** — the rarest tier. This requires 4,096 original tokens (25.6% of total supply) to have been burned in the process.

## Architecture

All rendering, metadata, color palettes, and transformation history live permanently on Ethereum with no external dependencies.

```
contracts/
├── Checks.sol              # Main ERC-721 contract (minting, compositing, burning)
├── Compositor.sol           # Recursive multi-token compositing in a single tx
├── standards/
│   ├── CHECKS721.sol        # Gas-optimized ERC-721 implementation
│   └── WithEpochs.sol       # Commit-reveal randomness system
├── libraries/
│   ├── ChecksArt.sol        # On-chain SVG generation
│   ├── ChecksMetadata.sol   # On-chain JSON metadata rendering
│   ├── EightyColors.sol     # 80-color gradient palette
│   └── Utilities.sol        # PRNG and math utilities
└── interfaces/
    ├── IChecks.sol           # Data structures and events
    ├── IChecksEdition.sol    # Zora Edition interface
    └── IERC4906.sol          # Metadata update events (EIP-4906)
```

### Epoch System

Visual properties use a commit-reveal randomness mechanism: properties are committed 50 blocks in advance, then revealed using the future blockhash. This prevents front-running and ensures fair random assignment.

### Generative Properties

Each token carries a unique combination of:

- **Color Band** — how many of the 80 palette colors are used (80, 60, 40, 20, 10, 5, or 1)
- **Gradient** — pattern type (None, Linear, Double Linear, Reflected, Double Angled, Angled, Linear Z)
- **Speed** — animation rate (0.5x, 1x, 2x)
- **Shift** — animation direction (IR, UV)
- **Day** — creation day relative to contract deployment

### Provenance

Every token carries its full transformation history — the family tree of burned parents and color/gradient evolution across composites.

## Contracts

### Mainnet

| Contract         | Address                                                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Checks Editions  | [`0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9`](https://etherscan.io/address/0x34eEBEE6942d8Def3c125458D1a86e0A897fd6f9) |
| Checks Originals | [`0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1`](https://etherscan.io/address/0x036721e5A769Cc48B3189EFbb9ccE4471E8A48B1) |

## Development

Built with [Hardhat](https://hardhat.org), Solidity 0.8.17, and [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts) v4.8.0.

### Setup

```shell
cp .env.example .env  # configure RPC URLs and keys
yarn install
```

### Commands

```shell
npx hardhat compile                       # Compile contracts
npx hardhat test                          # Run tests
REPORT_GAS=true npx hardhat test          # Run tests with gas reporting
npx hardhat coverage                      # Generate coverage report
npx solhint 'contracts/**/*.sol'          # Lint Solidity
npx prettier '**/*.{json,sol,md}' --check # Check formatting
```

## License

MIT
