// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {AssetHolder} from "../../src/game-assets/AssetHolder.sol";
import {AssetWrapper} from "../../src/game-assets/AssetWrapper.sol";
import {GameAsset} from "../../src/game-assets/GameAsset.sol";

contract GameAssetsTest is Test {
  Utilities private utils;
  address payable private attacker;
  address payable private user;

  AssetWrapper private assetWrapper;
  GameAsset private swordAsset;
  GameAsset private shieldAsset;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    assetWrapper = new AssetWrapper("");

    swordAsset = new GameAsset("SHIELD", "SHIELD");
    shieldAsset = new GameAsset("SHIELD", "SHIELD");

    assetWrapper.updateWhitelist(address(swordAsset));
    assetWrapper.updateWhitelist(address(shieldAsset));

    swordAsset.setOperator(address(assetWrapper));
    shieldAsset.setOperator(address(assetWrapper));

    swordAsset.mintForUser(user, 1);
    shieldAsset.mintForUser(user, 1);

    assertEq(swordAsset.balanceOf(user), 1);
    assertEq(shieldAsset.balanceOf(user), 1);

  }

  function testExploit() public {
    // Exploit start

    // Exploit end

    validate();
  }

  function validate() private {
  }
}
