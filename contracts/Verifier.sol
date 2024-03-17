// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {UltraVerifier as SplitJoin16Verifier_} from "@ultralane/circuits/bin/split_join_16/contract/split_join_16/plonk_vk.sol";
import {UltraVerifier as SplitJoin32Verifier_} from "@ultralane/circuits/bin/split_join_32/contract/split_join_32/plonk_vk.sol";
import {UltraVerifier as Hash2Verifier_} from "@ultralane/circuits/bin/hash_2/contract/hash_2/plonk_vk.sol";
import {UltraVerifier as NoteVerifier_} from "@ultralane/circuits/bin/note/contract/note/plonk_vk.sol";
import {UltraVerifier as Input16Verifier_} from "@ultralane/circuits/bin/input_16/contract/input_16/plonk_vk.sol";

contract SplitJoin16Verifier is SplitJoin16Verifier_ {}

contract SplitJoin32Verifier is SplitJoin32Verifier_ {}

contract Hash2Verifier is Hash2Verifier_ {}

contract NoteVerifier is NoteVerifier_ {}

contract Input16Verifier is Input16Verifier_ {}
