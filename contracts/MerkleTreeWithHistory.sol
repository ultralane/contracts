// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Poseidon2} from "./Poseidon2.sol";
import {Field, ImplField} from "./Field.sol";

contract MerkleTreeWithHistory {
    using ImplField for Field;

    uint32 public levels;

    // the following variables are made public for easier testing and debugging and
    // are not supposed to be accessed in regular code

    // filledSubtrees and roots could be bytes32[size], but using mappings makes it cheaper because
    // it removes index range check on every interaction
    mapping(uint256 => Field) public filledSubtrees; // Field[depth]
    mapping(uint256 => Field) public roots; // Field[ROOT_HISTORY_SIZE]
    uint32 public constant ROOT_HISTORY_SIZE = 30;
    uint32 public currentRootIndex = 0;
    uint32 public nextIndex = 0;

    constructor(uint32 _levels) {
        require(_levels > 0, "_levels should be greater than zero");
        require(_levels <= 32, "_levels should be less than eq 32");
        levels = _levels;

        for (uint32 i = 0; i < _levels; i++) {
            filledSubtrees[i] = zeros(i);
        }

        roots[0] = zeros(_levels - 1);
    }

    function _insert(Field leaf) internal returns (uint32 index) {
        uint32 _nextIndex = nextIndex;
        require(
            _nextIndex != uint32(2) ** levels,
            "Merkle tree is full. No more leaves can be added"
        );
        uint32 currentIndex = _nextIndex;
        Field currentLevelHash = leaf;
        Field left;
        Field right;

        for (uint32 i = 0; i < levels; i++) {
            if (currentIndex % 2 == 0) {
                left = currentLevelHash;
                right = zeros(i);
                filledSubtrees[i] = currentLevelHash;
            } else {
                left = filledSubtrees[i];
                right = currentLevelHash;
            }
            currentLevelHash = Poseidon2.hash_2(left, right);
            currentIndex /= 2;
        }

        uint32 newRootIndex = (currentRootIndex + 1) % ROOT_HISTORY_SIZE;
        currentRootIndex = newRootIndex;
        roots[newRootIndex] = currentLevelHash;
        nextIndex = _nextIndex + 1;
        return _nextIndex;
    }

    /**
    @dev Whether the root is present in the root history
  */
    function isKnownRoot(Field root) public view returns (bool) {
        if (root.isZero()) {
            return false;
        }
        uint32 _currentRootIndex = currentRootIndex;
        uint32 i = _currentRootIndex;
        do {
            if (root.eq(roots[i])) {
                return true;
            }
            if (i == 0) {
                i = ROOT_HISTORY_SIZE;
            }
            i--;
        } while (i != _currentRootIndex);
        return false;
    }

    /**
    @dev Returns the last root
  */
    function getLastRoot() public view returns (Field) {
        return roots[currentRootIndex];
    }

    /// @dev provides Zero (Empty) elements for a MiMC MerkleTree. Up to 32 levels
    function zeros(uint256 i) public pure returns (Field) {
        if (i == 0) return Field.wrap(0);
        else if (i == 1)
            return
                Field.wrap(
                    0x0b63a53787021a4a962a452c2921b3663aff1ffd8d5510540f8e659e782956f1
                );
        else if (i == 2)
            return
                Field.wrap(
                    0x0e34ac2c09f45a503d2908bcb12f1cbae5fa4065759c88d501c097506a8b2290
                );
        else if (i == 3)
            return
                Field.wrap(
                    0x21f9172d72fdcdafc312eee05cf5092980dda821da5b760a9fb8dbdf607c8a20
                );
        else if (i == 4)
            return
                Field.wrap(
                    0x2373ea368857ec7af97e7b470d705848e2bf93ed7bef142a490f2119bcf82d8e
                );
        else if (i == 5)
            return
                Field.wrap(
                    0x120157cfaaa49ce3da30f8b47879114977c24b266d58b0ac18b325d878aafddf
                );
        else if (i == 6)
            return
                Field.wrap(
                    0x01c28fe1059ae0237b72334700697bdf465e03df03986fe05200cadeda66bd76
                );
        else if (i == 7)
            return
                Field.wrap(
                    0x2d78ed82f93b61ba718b17c2dfe5b52375b4d37cbbed6f1fc98b47614b0cf21b
                );
        else if (i == 8)
            return
                Field.wrap(
                    0x067243231eddf4222f3911defbba7705aff06ed45960b27f6f91319196ef97e1
                );
        else if (i == 9)
            return
                Field.wrap(
                    0x1849b85f3c693693e732dfc4577217acc18295193bede09ce8b97ad910310972
                );
        else if (i == 10)
            return
                Field.wrap(
                    0x2a775ea761d20435b31fa2c33ff07663e24542ffb9e7b293dfce3042eb104686
                );
        else if (i == 11)
            return
                Field.wrap(
                    0x0f320b0703439a8114f81593de99cd0b8f3b9bf854601abb5b2ea0e8a3dda4a7
                );
        else if (i == 12)
            return
                Field.wrap(
                    0x0d07f6e7a8a0e9199d6d92801fff867002ff5b4808962f9da2ba5ce1bdd26a73
                );
        else if (i == 13)
            return
                Field.wrap(
                    0x1c4954081e324939350febc2b918a293ebcdaead01be95ec02fcbe8d2c1635d1
                );
        else if (i == 14)
            return
                Field.wrap(
                    0x0197f2171ef99c2d053ee1fb5ff5ab288d56b9b41b4716c9214a4d97facc4c4a
                );
        else if (i == 15)
            return
                Field.wrap(
                    0x2b9cdd484c5ba1e4d6efcc3f18734b5ac4c4a0b9102e2aeb48521a661d3feee9
                );
        else if (i == 16)
            return
                Field.wrap(
                    0x14f44d672eb357739e42463497f9fdac46623af863eea4d947ca00a497dcdeb3
                );
        else if (i == 17)
            return
                Field.wrap(
                    0x071d7627ae3b2eabda8a810227bf04206370ac78dbf6c372380182dbd3711fe3
                );
        else if (i == 18)
            return
                Field.wrap(
                    0x2fdc08d9fe075ac58cb8c00f98697861a13b3ab6f9d41a4e768f75e477475bf5
                );
        else if (i == 19)
            return
                Field.wrap(
                    0x20165fe405652104dceaeeca92950aa5adc571b8cafe192878cba58ff1be49c5
                );
        else if (i == 20)
            return
                Field.wrap(
                    0x1c8c3ca0b3a3d75850fcd4dc7bf1e3445cd0cfff3ca510630fd90b47e8a24755
                );
        else if (i == 21)
            return
                Field.wrap(
                    0x1f0c1a8fb16b0d2ac9a146d7ae20d8d179695a92a79ed66fc45d9da4532459b3
                );
        else if (i == 22)
            return
                Field.wrap(
                    0x038146ec5a2573e1c30d2fb32c66c8440f426fbd108082df41c7bebd1d521c30
                );
        else if (i == 23)
            return
                Field.wrap(
                    0x17d3d12b17fe762de4b835b2180b012e808816a7f2ff69ecb9d65188235d8fd4
                );
        else if (i == 24)
            return
                Field.wrap(
                    0x0e1a6b7d63a6e5a9e54e8f391dd4e9d49cdfedcbc87f02cd34d4641d2eb30491
                );
        else if (i == 25)
            return
                Field.wrap(
                    0x09244eec34977ff795fc41036996ce974136377f521ac8eb9e04642d204783d2
                );
        else if (i == 26)
            return
                Field.wrap(
                    0x1646d6f544ec36df9dc41f778a7ef1690a53c730b501471b6acd202194a7e8e9
                );
        else if (i == 27)
            return
                Field.wrap(
                    0x064769603ba3f6c41f664d266ecb9a3a0f6567cd3e48b40f34d4894ee4c361b3
                );
        else if (i == 28)
            return
                Field.wrap(
                    0x1595bb3cd19f84619dc2e368175a88d8627a7439eda9397202cdb1167531fd3f
                );
        else if (i == 29)
            return
                Field.wrap(
                    0x2a529be462b81ca30265b558763b1498289c9d88277ab14f0838cb1fce4b472c
                );
        else if (i == 30)
            return
                Field.wrap(
                    0x0c08da612363088ad0bbc78abd233e8ace4c05a56fdabdd5e5e9b05e428bdaee
                );
        else if (i == 31)
            return
                Field.wrap(
                    0x14748d0241710ef47f54b931ac5a58082b1d56b0f0c30d55fb71a6e8c9a6be14
                );
        else if (i == 32)
            return
                Field.wrap(
                    0x0b59baa35b9dc267744f0ccb4e3b0255c1fc512460d91130c6bc19fb2668568d
                );
        else revert("Index out of bounds");
    }
}
