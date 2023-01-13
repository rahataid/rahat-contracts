//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IRahatClaim.sol";
import "../interfaces/IRahatRegistry.sol";
import "../interfaces/IRahatToken.sol";

contract RahatCommunity is AccessControl {
    //***** Variables *********//
    string public name;
    IRahatClaim public RahatClaim;
    IRahatRegistry public RahatRegistry;
    IRahatToken public RahatToken;

    address public otpServerAddress;
    mapping(address => bool) isBeneficiary;
    address[] public projects;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR");

    //***** Modifiers *********//
    modifier OnlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    modifier OnlyVendor() {
        require(hasRole(VENDOR_ROLE, msg.sender), "Not a vendor");
        _;
    }

    //***** Constructor *********//
    constructor(
        string memory _name,
        IRahatClaim _rahatClaim,
        IRahatRegistry _rahatRegistry,
        address _otpServerAddress,
        address _admin
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(VENDOR_ROLE, DEFAULT_ADMIN_ROLE);
        name = _name;
        otpServerAddress = _otpServerAddress;
        RahatClaim = _rahatClaim;
        RahatRegistry = _rahatRegistry;
    }

    //***** Admin function *********//
    function updateClaimContractAddress(address _address) public OnlyAdmin {
        RahatClaim = IRahatClaim(_address);
    }

    function updateRegistryContractAddress(address _address) public OnlyAdmin {
        RahatRegistry = IRahatRegistry(_address);
    }

    function updateOtpServerAddress(address _address) public OnlyAdmin {
        otpServerAddress = _address;
    }

    //***** Project functions *********//
    function addProject(address _address) public OnlyAdmin {
        projects.push(_address);
    }

    //***** Beneficiary functions *********//
    function addBeneficiary(address _address) public OnlyAdmin {
        isBeneficiary[_address] = true;
    }

    function removeBeneficiary(address _address) public OnlyAdmin {
        isBeneficiary[_address] = false;
    }

    function addBeneficiaryById(bytes32 _id) public OnlyAdmin {
        address _addr = RahatRegistry.id2Address(_id);
        isBeneficiary[_addr] = true;
    }

    //***** Util functions *********//
    function _projectExists(address _tokenAddress) private view returns (bool) {
        for (uint i = 0; i < projects.length; i++) {
            if (projects[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
