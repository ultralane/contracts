// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Field, ImplField} from "../libraries/Field.sol";
import "hardhat/console.sol";

contract FieldTest {
    using ImplField for Field;
    using ImplField for uint256;
    using ImplField for int256;
    using ImplField for bytes32;
}
