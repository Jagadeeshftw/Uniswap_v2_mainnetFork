// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {IUniswapV2Factory} from "../src/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../src/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Router01} from "../src/interfaces/IUniswapV2Router01.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";

contract DeploymentTests is Test {
    IUniswapV2Factory factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

    IWETH deployedWeth = IWETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function setUp() public {
    }

    function test_uniswapFactory() public view {
        assert(factory.feeToSetter() != address(0));
    }

    function test_wrappedEther() public view {
        assert(abi.encode(deployedWeth.name()).length > 0);
    }

    function test_deployedRouter() public view {
        assert(router.WETH() != address(0));
    }
}
