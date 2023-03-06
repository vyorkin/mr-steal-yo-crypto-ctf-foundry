// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IBondingCurve, IEminenceCurrency} from "../../src/bonding-curve/EminenceIntefaces.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "uniswap-v2-core/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "uniswap-v2-core/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Router02} from "uniswap-v2-periphery/interfaces/IUniswapV2Router02.sol";
import {Token} from "../../src/Token.sol";
import {WETH9} from "../../src/WETH9.sol";

contract BondingCurveTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  IUniswapV2Factory private uniFactory;
  IUniswapV2Router02 private uniRouter;
  IUniswapV2Pair private uniPair;

  WETH9 private weth;
  Token private usdc;
  Token private dai;

  IEminenceCurrency private eminenceCurrencyBase; // EMN
  IEminenceCurrency private eminenceCurrency; // TOKEN

  IBondingCurve private bancorBondingCurve;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    usdc = new Token("USDC", "USDC");
    usdc.mint(address(this), 1_000_000e18);

    dai = new Token("DAI", "DAI");
    dai.mint(address(this), 1_000_000e18);
    dai.mint(user, 200_000e18);

    weth = new WETH9();

    uniFactory = IUniswapV2Factory(
        deployCode(
            "./build-uniswap/v2/UniswapV2Factory.json",
            abi.encode(address(this)) // feeToSetter
        )
    );
    uniRouter = IUniswapV2Router02(
        deployCode(
            "./build-uniswap/v2/UniswapV2Router02.json",
            abi.encode(address(uniFactory), address(weth))
        )
    );

    usdc.approve(address(uniRouter), type(uint256).max);
    dai.approve(address(uniRouter), type(uint256).max);

    uniRouter.addLiquidity(
      address(usdc),
      address(dai),
      1_000_000e18,
      1_000_000e18,
      0,
      0,
      address(this),
      block.timestamp
    );

    uniPair = IUniswapV2Pair(uniFactory.getPair(address(usdc), address(dai)));

    bancorBondingCurve = IBondingCurve(
      deployCode("out/BancorBondingCurve.sol/BancorBondingCurve.json")
    );

    // DAI <-> EMN bonding curve
    eminenceCurrencyBase = IEminenceCurrency(
      deployCode(
        "out/EminenceCurrencyBase.sol/EminenceCurrencyBase.json",
        abi.encode("Eminence", "EMN", 999000, address(dai))
      )
    );

    // EMN <-> TOKEN bonding curve
    eminenceCurrency = IEminenceCurrency(
      deployCode(
        "out/EminenceCurrency.sol/EminenceCurrency.json",
        abi.encode("eTOKEN", "TOKEN", 500000, address(eminenceCurrencyBase))
      )
    );

    eminenceCurrencyBase.addGM(address(eminenceCurrency));

    vm.startPrank(user);

    dai.approve(address(eminenceCurrencyBase), type(uint256).max);
    eminenceCurrencyBase.approve(address(eminenceCurrency), type(uint256).max);

    // swap all DAI to EMN
    eminenceCurrencyBase.buy(200_000e18, 0);
    // convert 1/2 EMN to TOKEN
    uint256 halfEMN = eminenceCurrencyBase.balanceOf(user) / 2;
    eminenceCurrency.buy(halfEMN, 0);

    vm.stopPrank();
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker, attacker);

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    assertGe(dai.balanceOf(attacker), 50_000e18);
  }
}
