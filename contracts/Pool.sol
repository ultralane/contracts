// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {
    IERC20 public usdc;

    constructor(IERC20 _usdc) {
        usdc = _usdc;
    }

    function deposit(
        uint amount,
        bytes32 noteCommitment,
        bytes memory proof
    ) external {
        // pull USDC
        usdc.transferFrom(msg.sender, address(this), amount);
    }
}
