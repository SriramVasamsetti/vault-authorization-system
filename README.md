# Authorization-Governed Vault System for Controlled Asset Withdrawals

A secure blockchain-based vault system implementing multi-contract authorization architecture for controlled asset withdrawals with cryptographic signature verification and replay attack prevention.

## Overview

This project demonstrates a sophisticated smart contract system where:
- A **SecureVault** contract holds and manages funds
- An **AuthorizationManager** contract validates withdrawal permissions
- Authorization is enforced via cryptographic signatures
- Each authorization can only be used once (replay protection)

## Architecture

### Smart Contracts

#### SecureVault.sol
- Manages fund deposits and withdrawals
- Relies entirely on AuthorizationManager for permission validation
- Maintains internal accounting of deposits
- Emits events for deposits and withdrawals
- Features:
  - `receive()` function for ETH deposits
  - `withdraw()` function for authorized withdrawals
  - Internal state management with invariant protection

#### AuthorizationManager.sol
- Validates withdrawal permissions via signature verification
- Tracks consumed authorizations to prevent replay attacks
- Uses ECDSA signature recovery for authentication
- Features:
  - `verifyAuthorization()` - validates and consumes authorizations
  - Deterministic message hashing
  - Signature recovery and validation

## Key Features

✅ **Multi-Contract Separation of Concerns**
- Vault handles fund management
- Authorization Manager handles permission validation

✅ **Cryptographic Security**
- ECDSA signature verification
- Deterministic message construction
- Replay attack prevention via authorization ID tracking

✅ **Atomicity Guarantees**
- State updates occur before value transfers
- Authorization consumption happens before withdrawal
- Prevents race conditions and reentrancy

✅ **Event Logging**
- Deposit events
- Withdrawal events
- Authorization consumption events

## Setup & Installation

### Prerequisites
- Docker and Docker Compose
- Node.js 18+ (for local development)
- npm or yarn

### Installation

```bash
git clone https://github.com/SriramVasamsetti/vault-authorization-system.git
cd vault-authorization-system
npm install
```

## Usage

### Using Docker Compose

The simplest way to deploy and test the system:

```bash
docker-compose up
```

This will:
1. Start a local Ganache blockchain node
2. Compile smart contracts
3. Deploy both contracts to the local blockchain
4. Output deployed contract addresses

### Manual Deployment

```bash
# Compile contracts
npm run compile

# Deploy contracts
npm run deploy
```

Deployment info will be saved to `deployment.json`.

## Authorization Flow

### Generating an Authorization

```javascript
const authorizationId = ethers.id("unique-auth-id");
const messageHash = ethers.solidityPacked(
  ['bytes32', 'address', 'address', 'uint256', 'uint256'],
  [authorizationId, vaultAddress, recipientAddress, amount, chainId]
);
const signature = await signer.signMessage(ethers.getBytes(messageHash));
```

### Performing a Withdrawal

```javascript
const tx = await vault.withdraw(
  authorizationId,
  recipientAddress,
  amount,
  chainId,
  signature
);
await tx.wait();
```

## Contract Interaction Example

```javascript
const ethers = require('ethers');

// Connect to blockchain
const provider = new ethers.JsonRpcProvider('http://localhost:8545');
const signer = provider.getSigner();

// Load deployment info
const deployment = require('./deployment.json');

// Create contract instances
const vault = new ethers.Contract(deployment.secureVault, vaultABI, signer);
const authManager = new ethers.Contract(deployment.authorizationManager, authABI, signer);

// Deposit funds
const depositTx = await signer.sendTransaction({
  to: deployment.secureVault,
  value: ethers.parseEther('10.0')
});
await depositTx.wait();

// Create and execute withdrawal
const authId = ethers.id('withdrawal-1');
const msgHash = ethers.solidityPacked(
  ['bytes32', 'address', 'address', 'uint256', 'uint256'],
  [authId, deployment.secureVault, recipientAddress, ethers.parseEther('5.0'), 31337]
);
const signature = await signer.signMessage(ethers.getBytes(msgHash));

const withdrawTx = await vault.withdraw(
  authId,
  recipientAddress,
  ethers.parseEther('5.0'),
  31337,
  signature
);
await withdrawTx.wait();
console.log('Withdrawal successful!');
```

## Testing

Optional: Create `tests/system.spec.js` to test:
- Successful deposits and withdrawals
- Failed authorization attempts
- Replay attack prevention
- State consistency across contract calls

## File Structure

```
vault-authorization-system/
├── contracts/
│   ├── AuthorizationManager.sol
│   └── SecureVault.sol
├── scripts/
│   └── deploy.js
├── docker/
│   └── Dockerfile
├── docker-compose.yml
├── hardhat.config.js
├── package.json
├── deployment.json (generated after deployment)
└── README.md
```

## Security Considerations

### Implemented Protections
1. **Signature Verification** - All authorizations are cryptographically signed
2. **Replay Prevention** - Authorization IDs can only be used once
3. **State Safety** - Internal accounting updated before value transfer
4. **Chain ID Binding** - Authorizations are bound to specific chain IDs
5. **Recipient Binding** - Each authorization specifies exact recipient
6. **Amount Binding** - Each authorization specifies exact withdrawal amount

### Design Principles
- Separation of concerns (Vault vs Authorization)
- Fail-safe defaults
- Explicit invariant checking
- Comprehensive event logging

## Deployment Information

After running `docker-compose up` or `npm run deploy`, deployment details are saved to `deployment.json`:

```json
{
  "authorizationManager": "0x...",
  "secureVault": "0x...",
  "deployer": "0x...",
  "chainId": 31337,
  "blockNumber": 0
}
```

## Troubleshooting

### Contract Compilation Fails
- Ensure Solidity version is 0.8.0 or higher
- Check for syntax errors in contract files

### Deployment Fails
- Ensure blockchain node is running (port 8545)
- Check sufficient gas and account balance
- Verify contract addresses in deployment.json

### Withdrawal Transaction Fails
- Verify authorization ID hasn't been used before
- Check authorization signature is valid
- Confirm sufficient vault balance
- Ensure correct chain ID in authorization

## Performance Notes

- Gas usage per withdrawal: ~65,000 gas (varies with network)
- Signature verification uses `ecrecover` (gas efficient)
- Authorization tracking via mapping (O(1) lookup)

## Future Enhancements

- Multi-signature authorizations
- Time-locked withdrawals
- Role-based access control
- Cross-chain authorization bridging
- Batch withdrawal support

## License

MIT

## Contact

For questions or issues, please open an issue on GitHub.
