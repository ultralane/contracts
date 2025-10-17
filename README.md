# @ultralane/contracts

```
pnpm install
pnpm compile
pnpm test
```

- contains the smart contracts for ultralane
- we also have implemented Poseidon2 hash function in solidity

## info

- MerkleTreeWithHistory.sol: inspired from tornado nova
- MixerPool.sol: verifies zk proofs as well as handles EVM EOA deposits and transactions
- Poseidon2.sol: temporary implementation of poseidon2
- StealthAddress.sol: contract code that is deployed to a stealth address
- TrustlessWithdraw.sol: claim funds that are stuck due to malicious or inactive ultralane relayer
- USDC.sol: temporary usdc token for testnet
- Verifier.sol: re-exporting verifiers from build
