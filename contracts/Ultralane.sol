// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {MixerPool, SplitJoin16Verifier, Hash2Verifier, NoteVerifier, IERC20} from "./MixerPool.sol";
import {TrustlessWithdraw, Input16Verifier, IMailbox} from "./TrustlessWithdraw.sol";

contract Ultralane is Ownable, MixerPool, TrustlessWithdraw {
    constructor(
        address owner,
        IERC20 usdc,
        SplitJoin16Verifier splitJoinVerifier,
        Hash2Verifier hash2Verifier,
        NoteVerifier noteVerifier,
        Input16Verifier input16Verifier,
        IMailbox mailbox
    )
        MixerPool(usdc, splitJoinVerifier, hash2Verifier, noteVerifier)
        TrustlessWithdraw(input16Verifier, mailbox)
        Ownable(owner)
    {}
}
