# Reclaim Protocol - Sui Move SDK

On-chain verification of Reclaim Protocol proofs on the Sui blockchain.

## Overview

This SDK enables developers to verify [Reclaim Protocol](https://reclaimprotocol.org/) zero-knowledge proofs directly on the Sui blockchain. It provides smart contracts for managing epochs, witnesses, and cryptographic verification of claims.

## Features

- **Proof Verification** - Verify Reclaim proofs on-chain with ECDSA signature recovery
- **Epoch Management** - Manage witness sets across different time periods
- **Dapp Registration** - Register decentralized applications with unique identifiers
- **Ethereum Compatibility** - Recover Ethereum addresses from secp256k1 signatures

## Prerequisites

- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install) (v1.59.0+)
- [Move](https://move-language.github.io/move/) knowledge

## Installation

Clone the repository:

```bash
git clone https://github.com/reclaimprotocol/move-sdk-onchain-integration.git
cd move-sdk-onchain-integration
```

## Build

```bash
sui move build
```

## Test

```bash
sui move test
```

For tests requiring higher gas limits:

```bash
sui move test -i 100000000000000000
```

## Publish

```bash
sui client publish --gas-budget 100000000
```

## Usage

### 1. Initialize Reclaim Manager

```move
use reclaim::reclaim;

// Create a new Reclaim Manager (one-time setup)
reclaim::create_reclaim_manager(
    epoch_duration_s,  // Duration of each epoch in seconds
    ctx
);
```

### 2. Add Witnesses (Admin Only)

```move
// Add a new epoch with witnesses
let witnesses = vector[
    x"244897572368eadf65bfbc5aec98d8e5443a9072"  // Witness ETH address
];

reclaim::add_new_epoch(
    &mut manager,
    witnesses,
    minimum_witnesses,  // Minimum signatures required
    ctx
);
```

### 3. Create and Verify Proofs

```move
// Create claim info
let claim_info = reclaim::create_claim_info(
    provider,    // Provider string (e.g., "http")
    parameters,  // JSON parameters
    context      // JSON context with extracted data
);

// Create claim data
let claim_data = reclaim::create_claim_data(
    identifier,   // Claim identifier (hash)
    owner,        // Claim owner address
    epoch,        // Epoch number
    timestamp_s   // Timestamp
);

// Create signed claim with signatures
let signed_claim = reclaim::create_signed_claim(claim_data, signatures);

// Create proof object
reclaim::create_proof(claim_info, signed_claim, ctx);

// Verify the proof
let signers = reclaim::verify_proof(&manager, &proof, ctx);
```

### 4. Register a Dapp

```move
reclaim::create_dapp(&mut manager, dapp_id, ctx);
```

## Module Structure

```
sources/
├── reclaim.move    # Core Reclaim protocol logic
└── ecdsa.move      # ECDSA utilities for signature verification

tests/
├── reclaim_tests.move  # Reclaim module tests
└── ecdsa_tests.move    # ECDSA module tests
```

## Deployments

| Network | Package Address |
|---------|-----------------|
| **Mainnet** | [`0xbfd81ff7150e0e85be1daab249353b887f78b9b076c78675a8b09311e4cd2089`](https://suivision.xyz/package/0xbfd81ff7150e0e85be1daab249353b887f78b9b076c78675a8b09311e4cd2089) |
| **Testnet** | [`0xbe2a8eb639d62527db3879a56ba3f400ad01f1633a5f665098b39b55e95e42a2`](https://testnet.suivision.xyz/package/0xbe2a8eb639d62527db3879a56ba3f400ad01f1633a5f665098b39b55e95e42a2) |
| **Devnet** | [`0xf476a131624dc8bbc380590915371e8bcd91b524ba7691f148239277cecb628e`](https://devnet.suivision.xyz/package/0xf476a131624dc8bbc380590915371e8bcd91b524ba7691f148239277cecb628e) |

## API Reference

### Structs

| Struct | Description |
|--------|-------------|
| `ReclaimManager` | Main contract state managing epochs and dapps |
| `Epoch` | Represents a time period with associated witnesses |
| `Proof` | A verified proof object containing claim info and signatures |
| `ClaimInfo` | Provider, parameters, and context for a claim |
| `SignedClaim` | Claim data with cryptographic signatures |

### Functions

| Function | Description |
|----------|-------------|
| `create_reclaim_manager` | Initialize the Reclaim Manager |
| `add_new_epoch` | Add a new epoch with witnesses (owner only) |
| `create_proof` | Create a proof object |
| `verify_proof` | Verify a proof against the current epoch |
| `create_dapp` | Register a new dapp |
| `get_provider_from_proof` | Extract provider from a proof |
| `fetch_epoch` | Get the current epoch |

## Security

- Proofs are verified using ECDSA signature recovery (secp256k1)
- Witnesses are selected deterministically based on claim hash
- Duplicate signature detection prevents replay attacks
- Only the owner can add new epochs

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Resources

- [Reclaim Protocol Documentation](https://docs.reclaimprotocol.org/)
- [Sui Move Documentation](https://docs.sui.io/concepts/sui-move-concepts)
- [Sui Developer Portal](https://sui.io/developers)
