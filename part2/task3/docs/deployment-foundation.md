# Sepolia deployment foundation (not executed)

This task intentionally avoids deployment, but includes deployment-ready scaffolding:
- `script/DeployAMM.s.sol` deployment script for `TokenA`, `TokenB`, and `AMM`.
- `.env.example` with `SEPOLIA_RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_API_KEY` placeholders.

Example command (do not run unless deployment is required):

```bash
forge script script/DeployAMM.s.sol:DeployAMM \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify
```
