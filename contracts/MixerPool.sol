// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Field, ImplField} from "./Field.sol";
import {SplitJoin16Verifier, Hash2Verifier, NoteVerifier} from "./Verifier.sol";
import {StealthAddress} from "./StealthAddress.sol";
import {MerkleTreeWithHistory} from "./MerkleTreeWithHistory.sol";

abstract contract MixerPool is MerkleTreeWithHistory, Ownable {
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
        IERC20 _usdc,
        SplitJoin16Verifier _splitJoinVerifier,
        Hash2Verifier _hash2Verifier,
        NoteVerifier _noteVerifier
    ) MerkleTreeWithHistory(16) {
        usdc = _usdc;
        splitJoinVerifier = _splitJoinVerifier;
        hash2Verifier = _hash2Verifier;
        noteVerifier = _noteVerifier;
        noteCommitments.push(ZERO_COMMITMENT);
        _insert(ZERO_COMMITMENT);
    }

    function deposit(
        uint amount,
        Field noteCommitment,
        bytes memory proof
    ) external {
        _createDepositUsingHash3(amount, noteCommitment, proof);
    }

    /// @notice Enables to send shielded funds to an ethereum address
    /// @dev proving split join takes about 5 seconds
    /// @param proof: zk proof that the two notes are valid and unspent
    /// @param publicInputs: [ROOT, AMOUNT, EVM_ADDRESS, NULLIFIER, NULLIFIER, COMMITMENT]
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
        emit NewCommitment(publicInputs[5]);
        noteCommitments.push(publicInputs[5]);
        _insert(publicInputs[5]);

        if (isDeposit) {
            // pull USDC
            usdc.transferFrom(msg.sender, address(this), amount);
        } else {
            // transfer USDC
            usdc.transfer(publicInputs[2].toAddress(), amount);
        }
    }

    /// @dev ultralane network verifies the zk proofs offchain and calls this function
    function crosschainTransact(
        address destination,
        uint amount,
        Field[] memory nullifiers,
        Field noteCommitment
    ) external onlyOwner {
        for(uint i; i < nullifiers.length; i++) {
            require(!isNoteSpent[nullifiers[i]], "Note is already spent");
            isNoteSpent[nullifiers[i]] = true;
            emit NullifierSpent(nullifiers[i]);
        }

        _insert(noteCommitment);
        emit NewCommitment(noteCommitment);
        noteCommitments.push(noteCommitment);

        usdc.transfer(destination, amount);
    }

    /// @notice Collect funds into the privacy layer
    /// @param token: erc20 token that is present on the stealth address
    /// @param balance: amount of tokens to collect into a UTXO note
    /// @param salt: hash of private key and a nonce
    /// @param stealthAddressOwnershipZkProof: salt preimage proof
    /// @param noteCommitment: hash of the note
    /// @param noteCreationZkProof: checks to ensure note has the right token and amount
    function collect(
        IERC20 token,
        uint balance,
        Field salt,
        bytes memory stealthAddressOwnershipZkProof,
        Field noteCommitment,
        bytes memory noteCreationZkProof
    ) external {
        require(
            // TODO critical bug: this should also constrain note commitment to
            // prevent relayer from using a different note.
            hash2Verifier.verify(stealthAddressOwnershipZkProof, salt.toArr()),
            "hash2 zk proof failed"
        );
        StealthAddress wallet = _deployIfNeeded(salt.toBytes32());
        wallet.transferErc20(token, address(this), balance);
        // TODO the note should include the token not just the balance in 
        // this PoC usdc seem to be hardcoded. So it depends if the underlying
        // privacy layer supports multiple tokens along with ETH.
        _createDepositUsingHash3(balance, noteCommitment, noteCreationZkProof);
    }

    /// @notice Compute the stealth address offchain
    /// @param salt: hash of a private key and a nonce
    function compute(Field salt) public view returns (address stealthAddress) {
        return Create2.computeAddress(salt.toBytes32(), INIT_CODE_HASH);
    }

    function allNoteCommitments() public view returns (Field[] memory) {
        return noteCommitments;
    }

    function noteCommitmentsLength() public view returns (uint256) {
        return noteCommitments.length;
    }

    function noteCommitmentsPaginated(
        uint start,
        uint length
    ) public view returns (Field[] memory) {
        Field[] memory result = new Field[](length);
        for (uint i = 0; i < length; i++) {
            result[i] = noteCommitments[start + i];
        }
        return result;
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

    /// @notice Inserts a deposit note into the huge append-only merkle tree
    /// @dev proving note takes about 1 sec
    /// @param amount: amount of tokens
    /// @param noteCommitment: hash of the note
    /// @param proof: zk proof that the noteCommitment's preimage contains the right amount
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
        noteCommitments.push(noteCommitment);
        _insert(noteCommitment);
    }

    /// @dev proving split join takes about 5 seconds
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
        noteCommitments.push(noteCommitment);
        _insert(noteCommitment);
    }
}
