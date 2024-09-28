// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "../src/interfaces/IUniswapV2Router01.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract DeploymentTests is Test {
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IWETH deployedWeth = IWETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IERC20 public DAI;
    IERC20 public USDC;
    address anvil_account1;

    function setUp() public {
        DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        anvil_account1 = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        console.log("the balance of DAI:", DAI.balanceOf(anvil_account1));
        console.log("the balance of USDC:", USDC.balanceOf(anvil_account1));

        deal(address(DAI), anvil_account1, 1000 * 1e18, true);
        //deal(address(USDC), anvil_account1, 100 * 1e18, true);
        console.log("the balance of DAI:", DAI.balanceOf(anvil_account1) / 1e18);
        console.log("the balance of USDC:", USDC.balanceOf(anvil_account1) / 1e18);
        vm.prank(anvil_account1);
        DAI.approve(address(router), type(uint256).max);
    }

    function test_pairExistence() public view {
        address pairAddress = factory.getPair(address(DAI), address(USDC));
        assert(pairAddress != address(0));
    }

    function test_swapping() public {
        uint256 amountIn = 100 * 1e18;
        address[] memory path = new address[](2);
        path[0] = address(DAI);
        path[1] = address(USDC);

        // Check expected USDC output
        uint256[] memory expectedAmounts = router.getAmountsOut(amountIn, path);
        uint256 amountOutMin = (expectedAmounts[1] * 95) / 100; // 5% slippage

        console.log("Expected USDC output (with 5% slippage):", amountOutMin / 1e6);

        address to = anvil_account1;
        vm.prank(anvil_account1);
        uint256[] memory amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp);
        assertGt(amounts[1], amountOutMin);
        console.log("DAI swapped:", amounts[0] / 1e18);
        console.log("USDC received:", amounts[1] / 1e6);
    }
}
