# Voxel World Pixel

**1,111 hand-crafted pixel-art NFTs on BNB Chain** — 12 characters (Robot, Cat, Astronaut, Alien, Wizard, Ninja, Pixel King, Panda, Frog, Pirate, Vampire, Dino), each drawn pixel by pixel on a 16×16 canvas with its own traits and rarity: Common, Rare, Epic (Evolve-only) and Legendary (Genesis-exclusive).

🌐 **Live site:** https://voxelworld.fun
🐦 **X:** https://x.com/VoxelWorldPixel

## Mint status

- **Free Mint — 1,000 pieces — SOLD OUT.** Reserved for Binance Agent ID holders (max 4 per wallet, Common/Rare draw pool only). All 1,000 were claimed in under an hour on launch night, 16 Nov 2026.
- **Genesis Mint — 111 pieces — LIVE.** 0.0015 BNB, open to all wallets (max 5 per wallet), full draw pool including Legendary.

## Contract

- **Address:** `0x097E34c0A1657537aA0D94d171D39AB3954Fee57` (BNB Chain)
- **BscScan:** https://bscscan.com/address/0x097E34c0A1657537aA0D94d171D39AB3954Fee57
- **Source verified on Sourcify (exact match):** https://sourcify.dev/#/lookup/0x097E34c0A1657537aA0D94d171D39AB3954Fee57
- Free Mint eligibility is checked on-chain against the SPACE ID Agent ID registry (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`): `freeMint` requires the wallet to hold an Agent ID.
- **Evolve:** burn 2 of your Voxels + 0.001 BNB to receive 1 Evolved Voxel, guaranteed at least +1 rarity tier (Legendary inputs stay Legendary; Evolved from Free pieces caps at Epic).
- Sale proceeds stay in the contract; the owner withdraws with `withdraw()`.

## How to mint

1. **AI Agent (recommended):** copy a ready-made prompt from https://voxelworld.fun and paste it to your AI agent — it calls `genesisMint(1)` with exactly 0.0015 BNB (1500000000000000 wei).
2. **Directly on the contract:** call `genesisMint(quantity)` with 0.0015 BNB per piece on BscScan or from your wallet.
3. The mint buttons on the website itself are a clearly labelled rehearsal simulation for practising the flow.

## On the site

- **Pixel Playground** — a holders-only browser mini-game: 5 stages (Night Meadow → King's Sky), play as your own Voxel; Evolved Voxels start with 4 lives.
- **Evolve / Upgrade** — burn 2, get 1 exclusive Evolved character.
- **Sticker Pack** — all 12 characters + 4 pixel text stickers as free 512×512 transparent PNGs, plus a full 2048×2048 sheet.

## Repo layout

- `index.html` — the full website (single self-contained file, served by GitHub Pages)
- `deploy.html` — owner-only contract deploy/admin page
- `contracts/VoxelWorldPixel.sol` — the ERC-721 contract source (OpenZeppelin, Solidity 0.8.24)
- `metadata/` — ERC-721 metadata for the 12 characters + 12 Evolved forms (served at voxelworld.fun/metadata/)
- `nfts/`, `stickers/` — the character and sticker PNG artwork
