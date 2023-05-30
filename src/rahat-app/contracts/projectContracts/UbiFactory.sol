//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

//RahatProjectFactory
interface UbiFactory {
  ///@dev Accept Tokens from Rahatdonor
  ///@dev Save the received token in a set.
  ///@dev Save the no. of tokens issued to track total tokens received
  function acceptToken(address _token, address _from, uint256 _amount) external returns (bool);

  ///@dev
  function allocateTokensToBeneficiary(
    address _rahatCommunity,
    address _beneficiary,
    uint256 _amount
  ) external returns (bool);
}
