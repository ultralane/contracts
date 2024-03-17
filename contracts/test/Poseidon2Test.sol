// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Field, ImplField} from "../Field.sol";
import {Poseidon2} from "../Poseidon2.sol";

contract Poseidon2Test {
    using ImplField for Field;
    using ImplField for uint256;
    using ImplField for int256;
    using ImplField for bytes32;
    using Poseidon2 for Poseidon2.Constants;

    function hash_1(Field m1) public pure returns (Field) {
        return Poseidon2.hash_1(m1);
    }

    function hash_1_twice(Field m1) public pure returns (Field) {
        Poseidon2.Constants memory poseidon = Poseidon2.load();
        poseidon.hash_1(m1); // temp
        return poseidon.hash_1(m1);
    }

    function hash_2(Field m1, Field m2) public pure returns (Field) {
        return Poseidon2.hash_2(m1, m2);
    }

    function hash_3(Field m1, Field m2, Field m3) public pure returns (Field) {
        return Poseidon2.hash_3(m1, m2, m3);
    }
}
