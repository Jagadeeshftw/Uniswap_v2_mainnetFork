// SPDX-License-Identifier: MIT

pragma solidity >=0.8.5;

import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract TestFlashSwap {
    IUniswapV2Pair private immutable pair;
    address private immutable token0;
    address private immutable token1;

    constructor(address _pair) {
        pair = IUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
    }

    function flashSwap(address token, uint256 amount) public {
        (uint256 amount0, uint256 amount1) = token == token0 ? (amount, uint256(0)) : (uint256(0), amount);

        bytes memory data = abi.encode(token, msg.sender);

        pair.swap({amount0Out: amount0, amount1Out: amount1, to: address(this), data: data});
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(msg.sender == address(pair), "not the pair contract");
        require(sender == address(this), "sender should be equal to this contract");

        (address token, address caller) = abi.decode(data, (address, address));

        uint256 amount = token == token0 ? amount0 : amount1;

        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        IERC20(token).transferFrom(caller, address(this), fee);
        IERC20(token).transfer(address(pair), amountToRepay);
    }
}
