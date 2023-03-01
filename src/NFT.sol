// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Counters} from "openzeppelin/utils/Counters.sol";
import {ERC721} from "openzeppelin/token/ERC721/ERC721.sol";

contract NFT is ERC721, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private _tokenId;

  constructor(string memory _name, string memory _symbol)
    ERC721(_name, _symbol) {}

  function mintForUser(address _to, uint256 _qty) external onlyOwner {
    for (uint256 i; i < _qty; ++i) {
      _mint(_to, _tokenId.current());
      _tokenId.increment();
    }
  }
}
