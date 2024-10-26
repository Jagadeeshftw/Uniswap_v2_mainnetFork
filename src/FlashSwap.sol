// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {console2} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";

contract TestFlashSwap {
    IUniswapV2Pair private immutable uniswapPair;
    address private immutable token0;
    address private immutable token1;

    struct SwapParams {
        // Router to execute first swap - tokenIn for tokenOut
        address router0;
        // Router to execute second swap - tokenOut for tokenIn
        address sushiswapRouter;
        // Token in of first swap
        address tokenIn;
        // Token out of first swap
        address tokenOut;
        // Amount in for the first swap
        uint256 amountIn;
        // Revert the arbitrage if profit is less than this minimum
        uint256 minProfit;
    }

    constructor(address _pair1) {
        uniswapPair = IUniswapV2Pair(_pair1);
        token0 = uniswapPair.token0();
        token1 = uniswapPair.token1();
    }

    function flashSwap(address token, SwapParams params) public {
        // Log initial balance of the contract
        uint256 initialBalance = IERC20(token).balanceOf(address(this)) / 1e18;
        console2.log("Contract balance before borrowing:", initialBalance);

        // Determine which token to borrow
        (uint256 amount0, uint256 amount1) =
            token == token0 ? (params.amountIn, uint256(0)) : (uint256(0), params.amountIn);

        // Encode data to pass along with the swap
        bytes memory data = abi.encode(token, msg.sender, params);

        // Initiate the flash swap
        uniswapPair.swap({amount0Out: amount0, amount1Out: amount1, to: address(this), data: data});
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external {
        require(msg.sender == address(uniswapPair), "Caller is not the pair contract");
        require(sender == address(this), "Sender should be this contract");

        // Decode the data to obtain token and caller information
        (address token, address caller, params) = abi.decode(data, (address, address, SwapParams));

        // Log balance after borrowing
        uint256 postBorrowBalance = IERC20(token).balanceOf(address(this)) / 1e18;
        console2.log("Contract balance after borrowing:", postBorrowBalance);

        // Determine the amount borrowed
        uint256 borrowedAmount = token == token0 ? amount0 : amount1;

        address[] memory path = new address[](2);
        path[0] = DAI;
        path[1] = WETH;

        IERC20(token).approve(address(sushiswapRouter), type(uint256).max);
        uint256[] memory amounts =
            sushiswapRouter.swapExactTokensForTokens(borrowedAmount, 0, path, address(this), block.timestamp);

        console2.log("amounts: %s", amounts[1]);
        // Calculate the 0.3% fee required to repay the borrowed amount

        uint256 fee = ((borrowedAmount * 3) / 997) + 1;
        uint256 amountToRepay = borrowedAmount + fee;
        console2.log("repay amount: %s", amountToRepay);
        cosole2.log("amount that we got through arbitrage: %s", amounts[1]);

        // Ensure the contract receives the fee from the caller
        IERC20(token).transferFrom(caller, address(this), fee);

        // Repay the loan plus fee
        IERC20(token).transfer(address(uniswapPair), amountToRepay);

        // Log final balance to confirm loan repayment
        uint256 finalBalance = IERC20(token).balanceOf(address(this)) / 1e18;
        console2.log("Contract balance after repayment:", finalBalance);
    }
}
