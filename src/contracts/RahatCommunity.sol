//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '../interfaces/IRahatClaim.sol';
import '../interfaces/IRahatProject.sol';
import '../interfaces/IRahatCommunity.sol';

/// @title Community contract to approve projects and beneficiaries
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat projects and beneficiaries
/// @dev Rahat Community supports UUPS Upgradeable contract
contract RahatCommunity is Initializable, UUPSUpgradeable, IRahatCommunity, AccessControlUpgradeable, Multicall {
  // #region ***** Events *********//
  event ProjectApprovalRequest(address indexed requestor, address indexed project);
  event ProjectApproved(address indexed);
  event ProjectRevoked(address indexed);

  event BeneficiaryAdded(address indexed);
  event BeneficiaryRemoved(address indexed);
  event Received(address, uint);

  // #endregion

  // #region ***** Variables *********//
  ///@notice name of the community
  string public name;

  ///@notice map the beneficiary address with boolean
  ///@dev checks if the address is beneficiary or not
  mapping(address => bool) public override isBeneficiary;

  ///@notice map the project address with boolean
  ///@dev checks if the project is approved or not
  mapping(address => bool) public override isProject;

  ///@notice constant for vendor role
  bytes32 public constant VENDOR_ROLE = keccak256('VENDOR');

  ///@notice constant for project interface id
  bytes4 public constant IID_RAHAT_PROJECT = type(IRahatProject).interfaceId;

  // #endregion

  // #region ***** Modifiers *********//
  ///@notice Modifier to check if the caller is an admin
  modifier OnlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Not an admin');
    _;
  }

  // #endregion
  ///@notice Initialize the contract
  ///@param _name Name of the community
  ///@param _admin Address of the admin
  ///@dev  called only once during the contract deployment
  function initialize(string memory _name, address _admin) public initializer {
    __AccessControl_init();
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _setRoleAdmin(VENDOR_ROLE, DEFAULT_ADMIN_ROLE);
    name = _name;
  }

  // #region ***** Role functions *********//
  ///@notice checks if  a given address is admin or not
  ///@param _address address to check
  function isAdmin(address _address) public view returns (bool) {
    return hasRole(DEFAULT_ADMIN_ROLE, _address);
  }

  ///@notice add new beneficiary
  ///@param _address address of the beneficiary
  ///@dev only admin can call this function
  function addBeneficiary(address _address) public OnlyAdmin {
    isBeneficiary[_address] = true;
    emit BeneficiaryAdded(_address);
  }

  ///@notice remove beneficiary
  ///@param _address address of the beneficiary
  ///@dev only admin can call this function
  function removeBeneficiary(address _address) public OnlyAdmin {
    isBeneficiary[_address] = false;
    emit BeneficiaryRemoved(_address);
  }

  // #endregion

  // #region ***** Project functions *********//

  ///@notice approve the project
  ///@param _projectAddress address of the project
  ///@dev only admin can call this function
  function approveProject(address _projectAddress) public OnlyAdmin {
    require(
      IERC165Upgradeable(_projectAddress).supportsInterface(IID_RAHAT_PROJECT),
      'project interface not supported'
    );
    if (!isProject[_projectAddress]) emit ProjectApproved(_projectAddress);
    isProject[_projectAddress] = true;
  }

  ///@notice revvoke the project approval
  ///@param _projectAddress address of the project
  ///@dev only admin can call this function
  function revokeProject(address _projectAddress) public OnlyAdmin {
    if (isProject[_projectAddress]) emit ProjectRevoked(_projectAddress);
    isProject[_projectAddress] = false;
  }

  ///@notice request project approval
  ///@param _projectAddress address of the project
  ///@dev any one can request for project approval
  function requestProjectApproval(address _projectAddress) public {
    emit ProjectApprovalRequest(tx.origin, _projectAddress);
  }

  ///@notice grant role with eth
  ///@param _role role to grant
  ///@param _account account to grant role
  ///@dev only admin can call this function
  function grantRoleWithEth(bytes32 _role, address _account) public OnlyAdmin {
    super.grantRole(_role, _account);
    if (_account.balance < 0.03 ether) {
      (bool success, ) = _account.call{ value: 0.05 ether }('');
      require(success, 'Communnity needs more ether.');
    }
  }

  ///@notice fallback function to recieve ether
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  ///@notice withdraw ether from the contract
  ///@param _to address to send ether
  ///@dev only admin can call this function
  function withdraw(address payable _to) public payable OnlyAdmin {
    (bool sent, ) = _to.call{ value: address(this).balance }('');
    require(sent, 'Failed to send Ether');
  }
  ///@notice authorize the upgrade 
  ///@dev only admin can call this function and overide the function from UUPSUpgradeable
  function _authorizeUpgrade(address) internal override OnlyAdmin {}

  // #endregion
}
