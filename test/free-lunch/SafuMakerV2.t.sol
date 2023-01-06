// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Utilities} from "../Utilities.sol";
import {Token} from "../../src/Token.sol";
import {WETH9} from "../../src/WETH9.sol";
import {ISafuFactory, ISafuPair, SafuMakerV2} from "../../src/free-lunch/SafuMakerV2.sol";

interface ISafuRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract SafuMakerV2Test is Test {
  Utilities private utils;
  address payable private attacker;

  // Base trading pair token
  Token private usdc;
  // Farm token
  Token private safu;
  // Native token
  WETH9 private weth;
  // SushiBar contract address, irrelevant for exploit
  address constant BAR_ADDRESS = 0x1111111111111111111111111111111111111111;

  SafuMakerV2 private safuMaker;
  ISafuFactory private safuFactory;
  ISafuRouter private safuRouter;
  // Starts with just one trading pool: USDC-SAFU
  ISafuPair private safuPair;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(1);
    attacker = users[0];
    vm.label(attacker, "Attacker");

    usdc = new Token("USDC", "USDC");
    usdc.mint(attacker, 100);
    usdc.mint(address(this), 1000000);

    weth = new WETH9();

    safuFactory = ISafuFactory(
        deployCode(
            "./node_modules/@uniswap/v2-core/build/UniswapV2Factory.json",
            abi.encode(address(this)) // feeToSetter
        )
    );

    safuRouter = ISafuRouter(
        deployCode(
            "./node_modules/@uniswap/v2-core/build/UniswapV2Router02.json",
            abi.encode(address(safuFactory), address(weth))
        )
    );

    // safuMaker = new SafuMakerV2(address(safuFactory), )
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker);


    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {

  }
}
