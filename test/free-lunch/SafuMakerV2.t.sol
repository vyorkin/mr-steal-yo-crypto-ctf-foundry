// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Utilities} from "../Utilities.sol";
import {Token} from "../../src/Token.sol";
import {SafuMakerV2} from "../../src/free-lunch/SafuMakerV2.sol";

contract SafuMakerV2Test is Test {
  Utilities private utils;
  address payable private attacker;

  Token private usdc;
  SafuMakerV2 private safeMakerV2;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(1);
    attacker = users[0];
    vm.label(attacker, "Attacker");
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
