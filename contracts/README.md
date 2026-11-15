# VoxelWorldPixel — Smart Contract

ERC-721 contract for **Voxel World Pixel** (BNB Chain), matching the rules on
https://voxelworld.fun.

- Total supply cap **1,111** = 1,000 Free Mint + 111 Genesis Mint
- **Free Mint** — 0 BNB, max **4 per wallet**, only for wallets the owner has
  marked as verified Binance Agent ID holders (`setAgentIdVerified`).
  Draws randomly from Common & Rare characters only — no Legendary.
- **Genesis Mint** — **0.0015 BNB** each, max **5 per wallet**, draws from all
  12 characters including Legendary.
- **Evolve** — burn 2 owned Voxels + **0.001 BNB**, receive 1 Evolved Voxel at
  least 1 rarity tier higher (Legendary inputs stay Legendary; Evolved made
  only from Free-origin Voxels is capped at Epic).
- **Proceeds stay in the contract.** The owner (the wallet that deploys) can
  withdraw the full balance anytime with `withdraw()`.

## Deploy (Remix)

1. Open https://remix.ethereum.org and create `VoxelWorldPixel.sol` with the
   contents of the contract file. Remix will fetch the OpenZeppelin imports
   automatically. Compile with Solidity **0.8.24**.
2. Connect your wallet in Remix (Injected Provider), set the network to
   **BNB Chain**, and deploy. The deploying wallet becomes the owner.
3. After deployment, call:
   - `setBaseURI("https://voxelworld.fun/metadata/")`
   - `setAgentIdVerified(<wallet>, true)` for each verified Agent ID holder
     (or the batch version)
   - `setMintOpen(true)` when the mint should open
4. Copy the deployed contract address into the website (replacing
   "Contract: TBA") and into the agent mint prompts.
5. Withdraw proceeds anytime with `withdraw()`.

## Notes

- Character draws use a block-based pseudo-random hash. Fine for a low-price
  mint; for a high-value launch, switch the draw to Chainlink VRF first.
- Metadata lives in the `metadata/` folder of this repo and is served at
  `https://voxelworld.fun/metadata/<characterId>.json`
  (Evolved: `evolved-<characterId>.json`).
