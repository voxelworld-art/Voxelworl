# VoxelWorldPixel — Smart Contract

ERC-721 contract for **Voxel World Pixel** (BNB Chain), matching the rules on
https://voxelworld.fun.

- Total supply cap **1,111** = 1,000 Free Mint + 111 Genesis Mint
- **Free Mint** — 0 BNB, max **4 per wallet**, only for Binance Agent ID
  holders. Eligibility is checked on-chain at mint time against the official
  Binance Agent ID registry — the SPACE ID Agent ID (.ai) identity NFT at
  `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`. The registry address is set
  once in the constructor and can never be changed; a wallet holding at
  least one Agent ID (`balanceOf > 0`) can free-mint.
  Draws randomly from Common & Rare characters only — no Legendary.
- **Genesis Mint** — **0.0015 BNB** each, max **5 per wallet**, draws from all
  12 characters including Legendary.
- **Evolve** — burn 2 owned Voxels + **0.001 BNB**, receive 1 Evolved Voxel at
  least 1 rarity tier higher (Legendary inputs stay Legendary; Evolved made
  only from Free-origin Voxels is capped at Epic).
- **Proceeds stay in the contract.** The owner (the wallet that deploys) can
  withdraw the full balance anytime with `withdraw()`.

## Deploy (easiest: the deploy page)

Open https://voxelworld.fun/deploy.html in a wallet browser, connect the
owner wallet, and click Deploy — the Agent ID registry argument is prefilled
and the metadata base URI is set right after deployment from the same page.
Mint starts closed; open it from step 03 on that page when ready.

## Deploy (Remix, alternative)

1. Open https://remix.ethereum.org and create `VoxelWorldPixel.sol` with the
   contents of the contract file. Remix will fetch the OpenZeppelin imports
   automatically. Compile with Solidity **0.8.24**.
2. Connect your wallet in Remix (Injected Provider), set the network to
   **BNB Chain**, and deploy **with the constructor argument**:
   `agentIdRegistry_` = `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.
   The deploying wallet becomes the owner.
3. After deployment, call:
   - `setBaseURI("https://voxelworld.fun/metadata/")`
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
