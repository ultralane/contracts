// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

import {Field, ImplField} from "./libraries/Field.sol";
import {MixerPool} from "./MixerPool.sol";
import {Input16Verifier} from "./Verifier.sol";
import {MerkleTreeWithHistory} from "./MerkleTreeWithHistory.sol";

abstract contract TrustlessWithdraw is MixerPool {
    using ImplField for Field;
    using ImplField for Field[];

    struct Chain {
        uint96 chainId;
        address ultralane;
    }

    struct WithdrawRequest {
        address user;
        Field nullifier;
        uint amount;
        uint256 chainCount;
        WithdrawalStatus status;
        mapping(uint32 chainId => bool) chains; // For keeping track of which chains have updated the above values
    }

    enum CrosschanMessageType {
        Query,
        Response
    }

    enum WithdrawalStatus {
        Pending,
        Completed,
        Rejected
    }

    event TrustlessWithdrawInit(
        address indexed user,
        Field indexed nullifier,
        uint amount
    );

    event TrustlessWithdrawUpdate(
        uint256 indexed requestId,
        uint32 indexed chain
    );

    event TrustlessWithdrawComplete(
        uint256 indexed requestId,
        WithdrawalStatus status
    );

    modifier onlyMailbox() {
        require(
            msg.sender == address(mailbox),
            "Ultralane: Caller is not the mailbox"
        );
        _;
    }

    Chain[] public chains;
    WithdrawRequest[] public withdrawRequests;
    Input16Verifier public input16Verifier;
    IMailbox private mailbox;

    constructor(Input16Verifier _input16Verifier, IMailbox _mailbox) {
        input16Verifier = _input16Verifier;
        mailbox = _mailbox;
    }

    // need ETH on this contract for crosschain message calls
    receive() external payable {}

    function registerChain(uint96 chainId, address ultralane) public {
        chains.push(Chain(chainId, ultralane));
    }

    function trustlessWithdrawInit(
        bytes memory proof,
        Field[] memory publicInputs
    ) public payable returns (uint totalValue) {
        (
            Field root,
            address user,
            uint amount,
            Field nullifier
        ) = parseInputZkProof(proof, publicInputs);
        require(isKnownRoot(root), "proving note against an unknown root");

        withdrawRequests.push();
        uint requestId = withdrawRequests.length - 1;
        WithdrawRequest storage request = withdrawRequests[requestId];
        request.user = user;
        request.nullifier = nullifier;
        request.amount = amount;
        emit TrustlessWithdrawInit(user, nullifier, amount);

        for (uint256 i = 0; i < chains.length; i++) {
            uint32 chainId = uint32(chains[i].chainId);
            address remoteAddress = chains[i].ultralane;
            if (chainId == block.chainid) continue;
            bytes memory queryData = abi.encode(requestId, nullifier);
            bytes memory message = abi.encode(
                CrosschanMessageType.Query,
                queryData
            );
            bytes32 _remoteAddress;
            assembly {
                _remoteAddress := remoteAddress
            }
            // query: is this nullifier spent on your chain?
            uint256 value = mailbox.quoteDispatch(
                chainId,
                _remoteAddress,
                message
            );
            totalValue += value;
            mailbox.dispatch{value: value}(chainId, _remoteAddress, message);
        }
    }

    function handle(
        uint32 _chainId,
        bytes32 _sender,
        bytes calldata _message
    ) external payable onlyMailbox {
        (CrosschanMessageType id, bytes memory data) = abi.decode(
            _message,
            (CrosschanMessageType, bytes)
        );
        if (id == CrosschanMessageType.Query) {
            // message: is this nullifier spent on this chain?
            (uint256 requestId, Field nullifier) = abi.decode(
                data,
                (uint256, Field)
            );
            bytes memory resultData = abi.encode(
                requestId,
                isNoteSpent[nullifier]
            );
            bytes memory message = abi.encode(
                CrosschanMessageType.Response,
                resultData
            );
            // response: yes or no (along with the request id so the parent can update the request)
            uint256 value = mailbox.quoteDispatch(_chainId, _sender, message);
            mailbox.dispatch{value: value}(_chainId, _sender, message);
        } else if (id == CrosschanMessageType.Response) {
            // message: hey the nullifier of this request id is spent or not.
            (uint256 requestId, bool isSpent) = abi.decode(
                data,
                (uint256, bool)
            );
            require(
                requestId < withdrawRequests.length,
                "Ultralane: Invalid request id"
            );
            WithdrawRequest storage request = withdrawRequests[requestId];

            emit TrustlessWithdrawUpdate(requestId, _chainId);
            if (request.status == WithdrawalStatus.Rejected) {
                // if the request is already rejected, then stop the process
                return;
            }

            require(
                request.status == WithdrawalStatus.Pending,
                "Ultralane: Request already processed"
            );
            require(
                !request.chains[_chainId],
                "Ultralane: Chain already updated"
            );

            request.chains[_chainId] = true;
            request.chainCount++;

            if (isSpent) {
                request.status = WithdrawalStatus.Rejected;
                emit TrustlessWithdrawComplete(requestId, request.status);
            }

            if (request.chainCount == chains.length) {
                usdc.transfer(request.user, request.amount);
                request.status = WithdrawalStatus.Completed;
                emit TrustlessWithdrawComplete(requestId, request.status);
            }
        }
    }

    function parseInputZkProof(
        bytes memory proof,
        Field[] memory publicInputs
    )
        internal
        view
        returns (Field root, address user, uint amount, Field nullifier)
    {
        root = publicInputs[0];
        user = publicInputs[1].toAddress();
        amount = Field.unwrap(publicInputs[2]);
        nullifier = publicInputs[3];

        require(
            input16Verifier.verify(proof, publicInputs.into()),
            "split join zk proof failed"
        );
    }
}
