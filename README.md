## Maldo

### Core Components

#### Registry Contract
`Registry.sol` is the main contract proposed idea, it currently has four* registries:
- Users: maps users' wallets to their profile info
- Services: maps a tasker service to the service's info
- Deals: maps a tasker deal to its info
- Ratings: maps deals to user feedback and scores, tracking service quality and user reputation

[!] We allow _anyone_ to interact with this Registry contract. In a later stage, we will restrict interactions exclusively to _MaldoWallets_, managed by an in-house API that handles wallet creation through Pimlico, or even through an authorized operator controlled by us.

#### Badges Reputation System

Not developed yet, but we would mint different badges to:
- users that achieve certain level of activity (# of deals completed, # of reviews)
- users that complete specific IRL courses
-

Also, we're exploring using [EIP-6909](https://eips.ethereum.org/EIPS/eip-6909)

#### MaldoToken

Not used at the moment. Ideally we would allow taskers to create deals only if they havve available stake tokens. That way, in case of a dispute the `DisputResolver` would slash the tasker's stake.

#### DisputeResolver

Not used. Kleros is pushing an off-chain approach for dispute resolution so we hold the tinkering/develop of this.

That said, we did some explorations with Kleros' Escrow and TCRs and we're ready to re-take this path of development to ensure full integration with the Kleros applications.

### Dependencies

We're currently using Pimlico to handle Wallet creation and interactions, we explored other alternatives, but in the end we opted for Pimlico.

### Testing

Not units, just a single integration test to ensure we can replicate the happy-path for the PoC website.

We'll definitely improve this in the near future :D