# Fuzz Testing vs Unit Testing (Task 1)

## Unit testing
Unit tests validate specific, predefined scenarios. They are precise and deterministic: each test sets up exact state, executes one action, and checks known outcomes.

Typical strengths:
- Fast feedback for core logic regressions.
- Clear mapping from requirement to test case.
- Easy debugging when a test fails.

Typical limits:
- Coverage depends on how well the developer predicts edge cases.
- Rare input combinations can be missed.

## Fuzz testing
Fuzz tests execute the same property repeatedly with randomly generated inputs. In Foundry, fuzzing is automatic when test functions accept parameters.

Typical strengths:
- Finds unexpected edge cases and state interactions.
- Better confidence for arithmetic ranges and boundary behavior.
- Helps validate invariants-like properties under broad input space.

Typical limits:
- Requires property-based assertions (not fixed expected values).
- Reproducing complex failures can require shrinking and replay.
- Alone, fuzzing does not replace requirement-specific tests.

## When to use each
Use **unit tests** for explicit functional requirements (mint, transfer, approve, transferFrom, revert paths). Use **fuzz tests** for generalized correctness properties (e.g., transfer conservation across random users and amounts). In production-grade smart contract projects, both are complementary: unit tests provide specification confidence, fuzz tests improve robustness confidence.
