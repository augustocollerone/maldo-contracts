# Maldo Contracts

Smart contracts for the Maldo decentralized marketplace

## Core Components

### Registry Contract (`Registry.sol`)

**User Management:**
- `stake(uint256)` / `unstake(uint256)` - Token staking/unstaking with MaldoToken
- `setProfile(string)` - Profile management (IPFS hash or string)

**Service Management:**
- `addService(string)` - Create service listings
- `updateService(uint40, string)` - Update service descriptions (tasker only)

**Deal & Rating System:**
- `createDeal(uint40, uint256, address, string)` - Create deals with escrow integration
- `rate(uint40, uint8, string)` - Dual-party rating system (0-5 scale)
- `dispute(uint40)` - Dispute resolution system

### Badges Contract (`Badges.sol`)

ERC1155-based reputation system with role-based access control:

**Features:**
- Badge creation and metadata management
- Role-based minting
- Soul-bound

## Architecture

**Data Structures:**
- **Users:** Profile + staked amount mapping
- **Services:** ID, tasker, status, description
- **Deals:** ID, service reference, beneficiary, escrow agreement, price
- **Ratings:** Reviewer, score (0-5), review text per service

**External Dependencies:**
- Kleros' escrow-2: https://github.com/kleros/escrow-v2/

**Commands:**
```bash
forge build                    # Compile contracts
forge test                     # Run test suite
forge coverage                 # Generate coverage report
forge test --gas-report        # Gas usage analysis
```