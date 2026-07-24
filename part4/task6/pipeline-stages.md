# CI/CD Pipeline Stages (Task 6)

## 1) Environment setup
- Workflow triggers on push and pull request.
- Repository is checked out.
- Foundry toolchain is installed and version-checked.

## 2) Build and test stage
- Part 1 Task 1 is compiled and tested (including coverage run).
- Part 2 Task 3 is compiled and tested with gas report enabled.
- Part 3 Task 5 is compiled and tested with gas report enabled.

This validates Solidity compilation, functional correctness, and execution-cost visibility in one pipeline.

## 3) Static analysis stage
- Slither is installed via pip.
- Security/static-analysis summary is generated for:
  - `part2/task3`
  - `part3/task5`

This stage helps detect common smart-contract risks early (reentrancy patterns, missing checks, low-level call hazards, etc.).

## 4) Notes on fork tests
Fork tests (Part 1 Task 2) require a live `MAINNET_RPC_URL`, so they are intentionally not hard-required in this baseline CI file unless secrets are provisioned.
