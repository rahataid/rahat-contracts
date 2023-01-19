//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IRahatProject {
  function name() external view returns (string memory);

  function isLocked() external view returns (bool);

  function community() external view returns (address);

  function isBeneficiary(address _address) external view returns (bool);

  function beneficiaryCount() external view returns (uint256);

  function tokenBudget(address _tokenAddress) external view returns (uint);
}
