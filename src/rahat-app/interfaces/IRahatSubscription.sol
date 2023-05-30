//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IRahatSubscription {
  function isActive(address _address) external view returns (bool);

  function expiryDate(address _address) external returns (uint);

  function allowedBeneficiaryCount(address _address) external returns (uint);

  function allowedProjectCount(address _address) external returns (uint);

  function remainingBeneficiaryCount(address _address) external returns (uint);

  function remainingProjectCount(address _address) external returns (uint);

  function addProjectBeneficiaryCount(
    address _address,
    address _projectAddress,
    uint _beneficiaryCount
  ) external returns (uint);

  //only for Rahat Admin
  function updateSubcriptionDetails(
    address _address,
    address _projectAddress,
    uint _beneficiaryCount
  ) external returns (uint);

  function updateProjectBeneficiaryCount(
    address _address,
    address _projectAddress,
    uint _beneficiaryCount
  ) external returns (uint);
}
