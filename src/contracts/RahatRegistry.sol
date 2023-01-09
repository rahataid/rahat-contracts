//SPDX-License-Identifier: LGPL-3.0

pragma solidity ^0.8.16;

import "../libraries/AbstractOwner.sol";
import "../interfaces/IRahatRegistry.sol";

/// @title Donor contract to create tokens
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat tokens and projects
/// @dev All function calls are only executed by contract owner
contract RahatRegistry is AbstractOwner, IRahatRegistry {

  mapping(bytes32=>address) public override id2Address;

  constructor(
    address _admin
  ) {
    addOwner(_admin);
  }

  function addId2AddressMap(bytes32 _id, address _address) public override OnlyOwner returns(bool) {
    id2Address[_id] = _address;
    return true;
  }

  function exists(bytes32 _id) public override view returns(bool){
    return id2Address[_id]!=address(0);
  }
}

