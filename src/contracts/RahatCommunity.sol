//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RahatCommunity is AccessControl {

    mapping(address=>bool) isBeneficiary;
    mapping(address=>mapping(address=>uint256)) claims;


    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");
    bytes32 public constant SERVER_ROLE = keccak256("SERVER");

    //***** Modifiers *********//
    modifier OnlyServer() {
        require(
            hasRole(SERVER_ROLE, msg.sender),
            "Not a server"
        );
        _;
    }
    modifier OnlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not an admin"
        );
        _;
    }

    modifier OnlyVendor() {
        require(
            hasRole(VENDOR_ROLE, msg.sender),
            "Not a vendor"
        );
        _;
    }

    function addBeneficiary(address _address) public OnlyAdmin {}
    function addBeneficiaryById(bytes32 _id) public OnlyAdmin {}
}
