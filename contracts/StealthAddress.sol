// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StealthAddress {
    address public pool;

    constructor() {
        pool = msg.sender;
    }

    modifier onlyPool() {
        require(msg.sender == pool, "only factory");
        _;
    }

    receive() external payable {}

    function transferErc20(
        IERC20 token,
        address dest,
        uint amount
    ) external onlyPool returns (bool success) {
        return token.transfer(dest, amount);
    }

    function call(
        address dest,
        uint value,
        bytes calldata data
    ) external onlyPool returns (bool success, bytes memory returndata) {
        (success, returndata) = dest.call{value: value}(data);
    }
}