# Fork testing: vm.createSelectFork and vm.rollFork

`vm.createSelectFork(rpcUrl)` creates a local fork from a remote chain RPC and selects it as active execution context. Tests can then call real deployed contracts with their production state (storage, code, balances) without touching the live chain.

`vm.rollFork(blockNumber)` moves the active fork to a specific block number. This is useful for deterministic replay of historical states, temporal scenario testing, and simulating progression to future blocks on the fork.

## Benefits of fork testing
- Real protocol state and bytecode: much closer to production behavior than mocks.
- Integration confidence for contract-to-contract interactions.
- Useful for reproducing incidents and validating assumptions against mainnet data.

## Limitations of fork testing
- Depends on RPC quality, rate limits, and archive capabilities.
- Can be slower and less deterministic if tests target latest block instead of pinned blocks.
- Does not replace unit/invariant tests for isolated logic guarantees.
