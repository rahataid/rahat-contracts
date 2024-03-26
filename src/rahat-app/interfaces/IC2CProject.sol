// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.20;

import './IRahatProject.sol';
import './IRahatClaim.sol';

interface IC2CProject {
  /**
   * @dev Emitted when a claim is assigned to a beneficiary.
   * @param _beneficiary The address of the beneficiary.
   * @param _claimAmount The amount of the claim assigned.
   */
  event ClaimAssigned(address indexed _beneficiary, uint _claimAmount);

  /**
   * @dev Emitted when a claim is processed.
   * @param _beneficiary The address of the beneficiary.
   * @param _token The address of the token.
   * @param _amount The amount of tokens processed.
   */
  event ClaimProcessed(address indexed _beneficiary, address indexed _token, uint _amount);

  /**
   * @dev Retrieves the address of the default token.
   * @return The address of the default token.
   */
  function defaultToken() external returns (address);

  /**
   * @dev Checks if the given address is a donor.
   * @param _address The address to check.
   * @return A boolean value indicating whether the address is a donor or not.
   */
  function isDonor(address _address) external returns (bool);

  /**
   * @dev Allows the beneficiary to claim a certain amount of funds.
   * @param _address The address of the beneficiary.
   * @return The amount of funds claimed by the beneficiary.
   */
  function beneficiaryClaims(address _address) external returns (uint256);

  /**
   * @dev Assigns a claim to a beneficiary.
   * @param _beneficiary The address of the beneficiary.
   * @param _amount The amount of the claim to assign.
   */
  function assignClaims(address _beneficiary, uint _amount) external;

  /**
   * @dev Allows the contract to accept tokens from a specified address.
   * @param _from The address from which the tokens are being transferred.
   * @param _amount The amount of tokens being transferred.
   */
  function acceptToken(address _from, uint _amount) external;

  /**
   * @dev Allows the user to withdraw tokens from the contract.
   * @param _token The address of the token to be withdrawn.
   */
  function withdrawToken(address _token) external;

  /**
   * @dev Returns the total number of claims assigned.
   * @return _totalClaims The total number of claims assigned as an unsigned integer.
   */
  function totalClaimsAssigned() external view returns (uint256 _totalClaims);
}
