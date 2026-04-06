// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract LPToken {
    error NotAmm();
    error ZeroAddress();
    error InsufficientBalance();

    string public constant name = "AMM LP Token";
    string public constant symbol = "AMMLP";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    address public immutable amm;

    mapping(address => uint256) public balanceOf;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor(address ammAddress) {
        amm = ammAddress;
    }

    modifier onlyAmm() {
        if (msg.sender != amm) revert NotAmm();
        _;
    }

    function mint(address to, uint256 amount) external onlyAmm {
        if (to == address(0)) revert ZeroAddress();
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(address from, uint256 amount) external onlyAmm {
        uint256 userBalance = balanceOf[from];
        if (userBalance < amount) revert InsufficientBalance();
        balanceOf[from] = userBalance - amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);
    }
}
