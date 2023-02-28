// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "openzeppelin/utils/Address.sol";

/// @dev this is the proxy contract
contract SafuWallet {
  using Address for address;

  // FIELDS
  address constant _safuWalletLibrary = 0x2e234DAe75C793f67A35089C9d99245E1C58470b; // logic address

  // the number of owners that must confirm the same operation before it is run.
  uint public m_required;
  // pointer used to find a free slot in m_owners
  uint public m_numOwners;

  uint public m_dailyLimit;
  uint public m_spentToday;
  uint public m_lastDay;

  // list of owners
  uint[256] m_owners;

  event Deposit(address _from, uint value);

  /// @dev calls the `initWallet` method of the Library in this context
  constructor(address[] memory _owners, uint _required, uint _daylimit) {
    bytes memory data = abi.encodeWithSignature(
      "initWallet(address[],uint256,uint256)",
      _owners,
      _required,
      _daylimit
    );

    _safuWalletLibrary.functionDelegateCall(data);
  }

  // Gets an owner by 0-indexed position (using numOwners as the count)
  function getOwner(uint ownerIndex) external view returns (address) {
    return address(uint160(m_owners[ownerIndex + 1]));
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  fallback() external {
    _safuWalletLibrary.functionDelegateCall(msg.data);
  }
}
