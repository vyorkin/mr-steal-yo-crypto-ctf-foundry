// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";

contract Token is ERC20, Ownable {
  constructor(
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol) {}

  /// @dev mints specified amount for user
  function mint(address user, uint256 amount) external onlyOwner {
    _mint(user, amount);
  }
}
