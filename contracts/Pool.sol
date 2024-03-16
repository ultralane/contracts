// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Field, ImplField} from "./libraries/Field.sol";
import {SplitJoin16Verifier, Hash2Verifier, NoteVerifier} from "./Verifier.sol";
import {StealthAddress} from "./StealthAddress.sol";
import {MerkleTreeWithHistory} from "./MerkleTreeWithHistory.sol";
import "hardhat/console.sol";

contract Pool is MerkleTreeWithHistory {
    using ImplField for Field;
    using ImplField for uint256;
    using ImplField for int256;
    using ImplField for bytes32;
    using ImplField for address;
    using ImplField for Field[];

    Field constant FIELD_ZERO = Field.wrap(0);

    Field public constant ZERO_ROOT =
        Field.wrap(
            0x087486f7f14f265e263a4a6e776d45c15664d2dcb8c72288f4acf7fe1daeedaf
        );
    Field public constant ZERO_COMMITMENT =
        Field.wrap(
            0x0ecc1f56d6a29051a511ea4b08361649d190b7f7525a9d4ed36b9041e127207a
        );
    Field public constant ZERO_NULLIFIER =
        Field.wrap(
            0x262540451c6dd240fa72641be24bca61b14a3e5101df5633ef8d4f9e669eddb2
        );

    bytes32 public constant INIT_CODE_HASH =
        keccak256(type(StealthAddress).creationCode);

    IERC20 public usdc;
    SplitJoin16Verifier public splitJoinVerifier;
    Hash2Verifier public hash2Verifier;
    NoteVerifier public noteVerifier;

    mapping(Field nullifier => bool isSpent) public isNoteSpent;
    Field[] public noteCommitments;

    event NewCommitment(Field commitment);
    event NullifierSpent(Field commitment);

    constructor(
        SplitJoin16Verifier _splitJoinVerifier,
        Hash2Verifier _hash2Verifier,
        NoteVerifier _noteVerifier,
        IERC20 _usdc
    ) MerkleTreeWithHistory(16) {
        splitJoinVerifier = _splitJoinVerifier;
        hash2Verifier = _hash2Verifier;
        noteVerifier = _noteVerifier;
        usdc = _usdc;
        _insert(ZERO_COMMITMENT);
    }

    function deposit(
        uint amount,
        Field noteCommitment,
        bytes memory proof
    ) external {
        _createDepositUsingHash3(amount, noteCommitment, proof);
    }

    // proving split join takes about 5 seconds
    function transact(
        bytes memory proof,
        Field[] memory publicInputs
    ) external {
        // verify that the note has not been spent
        require(isKnownRoot(publicInputs[0]), "Deposits root unknown");
        (bool isDeposit, uint amount) = publicInputs[1].signed();

        if (!publicInputs[3].eq(ZERO_NULLIFIER)) {
            require(!isNoteSpent[publicInputs[3]], "Note is spent");
            isNoteSpent[publicInputs[3]] = true;
            emit NullifierSpent(publicInputs[3]);
        }
        if (!publicInputs[4].eq(ZERO_NULLIFIER)) {
            require(!isNoteSpent[publicInputs[4]], "Note is spent");
            isNoteSpent[publicInputs[4]] = true;
            emit NullifierSpent(publicInputs[4]);
        }

        require(
            splitJoinVerifier.verify(proof, publicInputs.into()),
            "split join zk proof failed"
        );

        // insert note in merkle tree and calculate new root
        emit NewCommitment(publicInputs[4]);
        noteCommitments.push(publicInputs[4]);
        _insert(publicInputs[4]);

        if (isDeposit) {
            // pull USDC
            usdc.transferFrom(msg.sender, address(this), amount);
        } else {
            // transfer USDC
            usdc.transfer(publicInputs[2].toAddress(), amount);
        }
    }

    function collect(
        IERC20 token,
        uint balance,
        Field salt,
        bytes memory stealthAddressOwnershipZkProof,
        Field noteCommitment,
        bytes memory noteCreationZkProof
    ) external {
        require(
            hash2Verifier.verify(stealthAddressOwnershipZkProof, salt.toArr()),
            "hash2 zk proof failed"
        );
        StealthAddress wallet = _deployIfNeeded(salt.toBytes32());
        wallet.transferErc20(token, address(this), balance);
        _createDepositUsingHash3(balance, noteCommitment, noteCreationZkProof);
    }

    function compute(Field salt) public view returns (address stealthAddress) {
        return Create2.computeAddress(salt.toBytes32(), INIT_CODE_HASH);
    }

    function _deployIfNeeded(bytes32 salt) internal returns (StealthAddress) {
        address computed = Create2.computeAddress(salt, INIT_CODE_HASH);
        uint size;
        assembly {
            size := extcodesize(computed)
        }
        if (size == 0) {
            bytes memory bytecode = type(StealthAddress).creationCode;
            address deployed;
            assembly {
                deployed := create2(
                    0,
                    add(bytecode, 0x20),
                    mload(bytecode),
                    salt
                )
            }
            require(
                deployed != address(0),
                "WalletFactory: failed to deploy wallet"
            );
            require(deployed == computed, "WalletFactory: deploy mismatch");
        }
        return StealthAddress(payable(computed));
    }

    // proving note takes about 1 sec
    function _createDepositUsingHash3(
        uint amount,
        Field noteCommitment,
        bytes memory proof
    ) internal {
        // verify that amount is in note commitment preimage using the zk proof
        Field[] memory publicInputs = new Field[](2);
        publicInputs[0] = amount.toField();
        publicInputs[1] = noteCommitment;

        require(
            noteVerifier.verify(proof, publicInputs.into()),
            "note zk proof failed"
        );

        // insert note in merkle tree and calculate new root
        // TODO this requires poseidon2 to be implemented in solidity,
        // temporarily taking this from solidity
        // proving the new deposit root will cause mutex issue hence
        // we have to do poseidon2 in solidity to allow parallel users.
        noteCommitments.push(noteCommitment);
        _insert(noteCommitment);
    }

    // proving split join takes about 5 seconds
    function _createDepositUsingSplitJoin(
        uint amount,
        Field noteCommitment,
        bytes memory proof
    ) internal {
        // verify that amount is in note commitment preimage using the zk proof
        Field[] memory publicInputs = new Field[](6);
        publicInputs[0] = ZERO_ROOT;
        publicInputs[1] = amount.toField();
        publicInputs[2] = FIELD_ZERO;
        publicInputs[3] = ZERO_NULLIFIER;
        publicInputs[4] = ZERO_NULLIFIER;
        publicInputs[5] = noteCommitment;

        require(
            splitJoinVerifier.verify(proof, publicInputs.into()),
            "split join zk proof failed"
        );

        // insert note in merkle tree and calculate new root
        // TODO this requires poseidon2 to be implemented in solidity,
        // temporarily taking this from solidity
        // proving the new deposit root will cause mutex issue hence
        // we have to do poseidon2 in solidity to allow parallel users.
        noteCommitments.push(noteCommitment);
        _insert(noteCommitment);
    }
}
