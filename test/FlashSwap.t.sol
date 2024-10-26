// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {Test, console2} from "forge-std/Test.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../src/interfaces/IUniswapV2Pair.sol";
import {
    DAI, WETH, UNISWAP_V2_ROUTER_02, UNISWAP_V2_PAIR_DAI_WETH, SUSHISWAP_V2_PAIR_DAI_WETH
} from "../src/Constants.sol";
import {TestFlashSwap} from "../src/FlashSwap.sol";

contract FlashSwapTest is Test {
    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant weth = IERC20(WETH);

    IUniswapV2Router02 private constant router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02);
    IUniswapV2Pair private constant uniswapPair = IUniswapV2Pair(UNISWAP_V2_PAIR_DAI_WETH);
    IUniswapV2Pair private constant suchiswapPair = IUniswapV2Pair(SUSHISWAP_V2_PAIR_DAI_WETH);
    TestFlashSwap private flashSwap;

    address private constant user = address(100);

    function setUp() public {
        flashSwap = new TestFlashSwap(UNISWAP_V2_PAIR_DAI_WETH);

        deal(DAI, user, 30000 * 1e18);
        deal(WETH, user, 1000 * 1e18);
        vm.prank(user);
        dai.approve(address(flashSwap), type(uint256).max);
    }

    function executeWethToDaiSwap() public {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = DAI;
        vm.prank(user);
        weth.approve(address(router), type(uint256).max);

        vm.prank(user);
        router.swapExactTokensForTokens({
            amountIn: 100 * 1e18,
            amountOutMin: 1,
            path: path,
            to: user,
            deadline: block.timestamp
        });
    }

    function logPoolState(IUniswapV2Pair pair) public view {
        console2.log(address(pair) == address(uniswapPair) ? "Uniswap pool" : "Sushiswap pool");
        (uint112 reserveDAI, uint112 reserveWETH,) = pair.getReserves();
        console2.log("DAI in pool: %s", reserveDAI / 1e18);
        console2.log("WETH in pool: %s", reserveWETH / 1e18);
        console2.log("WETH/DAI price: %s", reserveDAI / reserveWETH);
    }

    function test_flashSwapDAI() public {
        uint256 initialDAIBalance = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);
        vm.prank(user);
        flashSwap.flashSwap(DAI, 1e6 * 1e18);
        uint256 finalDAIBalance = dai.balanceOf(UNISWAP_V2_PAIR_DAI_WETH);

        console2.log("DAI swap fee: %s", finalDAIBalance - initialDAIBalance);
        assertGe(finalDAIBalance, initialDAIBalance, "DAI balance in pair decreased");
    }

    function test_executeArbitrage() public {
        logPoolState(uniswapPair);
        logPoolState(suchiswapPair);

        // Reduce WETH price to create arbitrage opportunity
        //executeWethToDaiSwap();

        vm.prank(user);
        flashSwap.flashSwap(DAI, 7e6 * 1e18);
        logPoolState(uniswapPair);
    }
}
