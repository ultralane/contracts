// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

type Field is uint256;

library ImplField {
    uint constant PRIME =
        0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001;
    uint constant PRIME_DIV_2 =
        0x183227397098d014dc2822db40c0ac2e9419f4243cdcb848a1f0fac9f8000000;

    function checkField(Field a) internal pure {
        require(Field.unwrap(a) < PRIME, "Field: input is too large");
    }

    function toFieldUnchecked(uint256 a) internal pure returns (Field b) {
        b = Field.wrap(a);
    }
    function toField(uint256 a) internal pure returns (Field b) {
        b = Field.wrap(a);
        checkField(b);
    }

    function toFieldUnchecked(bytes32 a) internal pure returns (Field b) {
        assembly {
            b := a
        }
    }
    function toField(bytes32 a) internal pure returns (Field b) {
        assembly {
            b := a
        }
        checkField(b);
    }

    function toBytes32(Field a) internal pure returns (bytes32 b) {
        assembly {
            b := a
        }
    }

    function toAddress(Field a) internal pure returns (address b) {
        require(Field.unwrap(a) < (1 << 160), "Field: input is too large");
        assembly {
            b := a
        }
    }

    function toArr(Field a) internal pure returns (bytes32[] memory b) {
        b = new bytes32[](1);
        b[0] = toBytes32(a);
    }

    function toField(address a) internal pure returns (Field b) {
        assembly {
            b := a
        }
    }

    function toField(int256 a) internal pure returns (Field) {
        // return Field.wrap(a);
        if (a < 0) {
            require(uint(-a) < PRIME, "Field: input is too large");
            return Field.wrap(PRIME - uint256(-a));
        } else {
            require(uint(a) < PRIME, "Field: input is too large");
            return Field.wrap(uint256(a));
        }
    }

    function into(Field[] memory a) internal pure returns (bytes32[] memory b) {
        assembly {
            b := a
        }
    }

    function add(Field a, Field b) internal pure returns (Field c) {
        assembly {
            c := addmod(a, b, PRIME)
        }
    }

    function mul(Field a, Field b) internal pure returns (Field c) {
        assembly {
            c := mulmod(a, b, PRIME)
        }
    }

    function add(Field a, uint b) internal pure returns (Field c) {
        assembly {
            c := addmod(a, b, PRIME)
        }
    }

    function mul(Field a, uint b) internal pure returns (Field c) {
        assembly {
            c := mulmod(a, b, PRIME)
        }
    }

    function eq(Field a, Field b) internal pure returns (bool c) {
        assembly {
            c := eq(a, b)
        }
    }

    function isZero(Field a) internal pure returns (bool c) {
        assembly {
            c := eq(a, 0)
        }
    }

    function signed(
        Field a
    ) internal pure returns (bool positive, uint scalar) {
        uint256 raw = Field.unwrap(a);
        if (raw > PRIME_DIV_2) {
            return (false, PRIME - raw);
        } else {
            return (true, raw);
        }
    }
}
