// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Selfdestructable is UUPSUpgradeable {
    function destroy() public {
        selfdestruct(payable(msg.sender));
    }

    function _authorizeUpgrade(address) internal override  {}
}
