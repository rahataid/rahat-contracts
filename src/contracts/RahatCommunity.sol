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
    mapping(address => bool) isApprovedProject;
    mapping(address => mapping(address => uint)) claims; //benAddress=>tokenAddress=>amount;
    mapping(address => mapping(address => uint)) tokenRequestIds; //vendorAddress=>benAddress=>requestId;
    address[] public tokenAddresses;

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
    function approveProject(address _address) public OnlyAdmin {
        isApprovedProject[_address] = true;
    }

    function revokeProject(address _address) public OnlyAdmin {
        isApprovedProject[_address] = false;
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

    function addClaimToBeneficiary(
        address _address,
        address _tokenAddress,
        uint _amount
    ) public {
        require(isApprovedProject[msg.sender], "project not approved");
        require(isBeneficiary[_address], "not beneficiary");
        if (!_tokenExists(_tokenAddress)) tokenAddresses.push(_tokenAddress);

        claims[_address][_tokenAddress] = _amount;
    }

    //***** Claim functions *********//
    function requestTokenFromBeneficiary(
        address _benAddress,
        address _tokenAddress,
        uint _amount
    ) public OnlyVendor returns (uint requestId) {
        requestId = requestTokenFromBeneficiary(
            _benAddress,
            _tokenAddress,
            _amount,
            otpServerAddress
        );
    }

    function requestTokenFromBeneficiary(
        address _benAddress,
        address _tokenAddress,
        uint _amount,
        address _otpServerAddress
    ) public OnlyVendor returns (uint requestId) {
        require(otpServerAddress != address(0));
        require(
            claims[_benAddress][_tokenAddress] >= _amount,
            "not enough balace"
        );
        requestId = RahatClaim.createClaim(
            msg.sender,
            _benAddress,
            _otpServerAddress,
            _tokenAddress,
            _amount
        );
        tokenRequestIds[msg.sender][_benAddress] = requestId;
    }

    function processTokenRequest(
        address _benAddress,
        string memory _otp
    ) public {
        IRahatClaim.Claim memory _claim = RahatClaim.processClaim(
            tokenRequestIds[msg.sender][_benAddress],
            _otp
        );
        uint _benTokenBalance = claims[_claim.claimeeAddress][
            _claim.tokenAddress
        ];
        require(_benTokenBalance >= _claim.amount, "not enough balace");
        IRahatToken _token = IRahatToken(_claim.tokenAddress);
        _benTokenBalance -= _claim.amount;

        _token.transfer(_claim.claimerAddress, _claim.amount);
    }

    //***** Util functions *********//
    function _tokenExists(address _tokenAddress) private view returns (bool) {
        for (uint i = 0; i < tokenAddresses.length; i++) {
            if (tokenAddresses[i] == _tokenAddress) {
                return true;
            }
        }
        return false;
    }
}
