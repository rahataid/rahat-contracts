//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import '../libraries/AbstractTokenActions.sol';

/// @title Donor contract to create tokens
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat tokens and projects
/// @dev All function calls are only executed by contract owner

contract RahatWallet is AbstractTokenActions {
  constructor(address _admin) {
    addOwner(_admin);
  }
}
