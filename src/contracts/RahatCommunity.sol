//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '../interfaces/IRahatClaim.sol';
import '../interfaces/IRahatProject.sol';
import '../interfaces/IRahatCommunity.sol';

contract RahatCommunity is IRahatCommunity, AccessControl {
  // #region ***** Events *********//
  event ProjectApprovalRequest(
    address indexed requestor,
    address indexed project
  );
  event ProjectApproved(address indexed);
  event ProjectRevoked(address indexed);

  event BeneficiaryAdded(address indexed);
  event BeneficiaryRemoved(address indexed);
  // #endregion

  // #region ***** Variables *********//
  string public name;

  mapping(address => bool) public override isBeneficiary;
  mapping(address => bool) public override isProject;

  bytes32 public constant VENDOR_ROLE = keccak256('VENDOR');
  // #endregion

  // #region ***** Modifiers *********//
  modifier OnlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Not an admin');
    _;
  }

  // #endregion

  constructor(string memory _name, address _admin) {
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _setRoleAdmin(VENDOR_ROLE, DEFAULT_ADMIN_ROLE);
    name = _name;
  }

  // #region ***** Role functions *********//
  function isAdmin(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  function isVendor(address _address) public view returns (bool) {
    return hasRole(VENDOR_ROLE, _address);
  }

  function addBeneficiary(address _address) public OnlyAdmin {
    isBeneficiary[_address] = true;
    emit BeneficiaryAdded(_address);
  }

  function removeBeneficiary(address _address) public OnlyAdmin {
    isBeneficiary[_address] = false;
    emit BeneficiaryRemoved(_address);
  }

  // #endregion

  // #region ***** Project functions *********//

  function approveProject(address _projectAddress) public OnlyAdmin {
    if (!isProject[_projectAddress]) emit ProjectApproved(_projectAddress);
    isProject[_projectAddress] = true;
  }

  function revokeProject(address _projectAddress) public OnlyAdmin {
    if (isProject[_projectAddress]) emit ProjectRevoked(_projectAddress);
    isProject[_projectAddress] = false;
  }

  function requestProjectApproval(address _projectAddress) public {
    emit ProjectApprovalRequest(tx.origin, _projectAddress);
  }
  // #endregion
}
