// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestERC20} from "./TestERC20.sol";
import {SimplePriceOracle} from "./SimplePriceOracle.sol";

contract LendingPool {
    error ZeroAmount();
    error ExceedsLtv();
    error InsufficientCollateral();
    error PositionHealthy();

    struct Position {
        uint256 deposited;
        uint256 borrowed;
        uint256 lastAccrued;
    }

    TestERC20 public immutable collateralToken;
    TestERC20 public immutable debtToken;
    SimplePriceOracle public immutable oracle;

    uint256 public constant LTV_BPS = 7500;
    uint256 public constant BPS = 10_000;
    uint256 public constant RATE_PER_SECOND_WAD = 158_548_960;

    mapping(address => Position) public positions;

    event Deposited(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Liquidated(address indexed user, address indexed liquidator, uint256 repaidDebt, uint256 seizedCollateral);

    constructor(address collateralTokenAddress, address debtTokenAddress, address oracleAddress) {
        collateralToken = TestERC20(collateralTokenAddress);
        debtToken = TestERC20(debtTokenAddress);
        oracle = SimplePriceOracle(oracleAddress);
    }

    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _accrue(msg.sender);

        positions[msg.sender].deposited += amount;
        collateralToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    function borrow(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _accrue(msg.sender);

        Position storage position = positions[msg.sender];

        uint256 maxBorrow = _maxBorrow(position.deposited);
        if (position.borrowed + amount > maxBorrow) revert ExceedsLtv();

        position.borrowed += amount;
        debtToken.transfer(msg.sender, amount);

        emit Borrowed(msg.sender, amount);
    }

    function repay(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _accrue(msg.sender);

        Position storage position = positions[msg.sender];
        uint256 debt = position.borrowed;
        uint256 repayAmount = amount > debt ? debt : amount;

        position.borrowed = debt - repayAmount;
        debtToken.transferFrom(msg.sender, address(this), repayAmount);

        emit Repaid(msg.sender, repayAmount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _accrue(msg.sender);

        Position storage position = positions[msg.sender];
        if (amount > position.deposited) revert InsufficientCollateral();

        uint256 newDeposit = position.deposited - amount;
        if (!_isHealthy(newDeposit, position.borrowed)) revert ExceedsLtv();

        position.deposited = newDeposit;
        collateralToken.transfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount);
    }

    function liquidate(address user) external {
        _accrue(user);

        Position storage position = positions[user];
        if (_isHealthy(position.deposited, position.borrowed)) revert PositionHealthy();

        uint256 debt = position.borrowed;
        uint256 collateral = position.deposited;

        position.borrowed = 0;
        position.deposited = 0;

        debtToken.transferFrom(msg.sender, address(this), debt);
        collateralToken.transfer(msg.sender, collateral);

        emit Liquidated(user, msg.sender, debt, collateral);
    }

    function getHealthFactor(address user) external view returns (uint256) {
        return _healthFactor(positions[user].deposited, _projectDebt(positions[user]));
    }

    function getProjectedBorrowed(address user) external view returns (uint256) {
        return _projectDebt(positions[user]);
    }

    function _accrue(address user) internal {
        Position storage position = positions[user];
        if (position.lastAccrued == 0) {
            position.lastAccrued = block.timestamp;
            return;
        }

        uint256 dt = block.timestamp - position.lastAccrued;
        if (dt > 0 && position.borrowed > 0) {
            uint256 interest = (position.borrowed * RATE_PER_SECOND_WAD * dt) / 1e18;
            position.borrowed += interest;
        }
        position.lastAccrued = block.timestamp;
    }

    function _projectDebt(Position memory position) internal view returns (uint256) {
        if (position.lastAccrued == 0 || position.borrowed == 0) {
            return position.borrowed;
        }

        uint256 dt = block.timestamp - position.lastAccrued;
        uint256 interest = (position.borrowed * RATE_PER_SECOND_WAD * dt) / 1e18;
        return position.borrowed + interest;
    }

    function _maxBorrow(uint256 deposited) internal view returns (uint256) {
        uint256 collateralValue = (deposited * oracle.priceCollateralInDebt()) / 1e18;
        return (collateralValue * LTV_BPS) / BPS;
    }

    function _isHealthy(uint256 deposited, uint256 borrowed) internal view returns (bool) {
        if (borrowed == 0) return true;
        uint256 collateralValue = (deposited * oracle.priceCollateralInDebt()) / 1e18;
        return (borrowed * BPS) <= (collateralValue * LTV_BPS);
    }

    function _healthFactor(uint256 deposited, uint256 borrowed) internal view returns (uint256) {
        if (borrowed == 0) return type(uint256).max;
        uint256 collateralValue = (deposited * oracle.priceCollateralInDebt()) / 1e18;
        return (collateralValue * LTV_BPS * 1e18) / (borrowed * BPS);
    }
}
