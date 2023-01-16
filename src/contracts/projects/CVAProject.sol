//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ICVAProject.sol";
import "../../libraries/AbstractTokenActions.sol";
import "../../interfaces/IRahatClaim.sol";
import "../../interfaces/IRahatRegistry.sol";
import "../../interfaces/IRahatCommunity.sol";

//mapping(address=>mapping(address=>uint256)) public claims;

contract CVAProject is ICVAProject, AbstractTokenActions, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant VENDOR_ROLE = keccak256("VENDOR");
    bytes32 public constant DONOR_ROLE = keccak256("DONOR");
    bytes32 public constant COMMUNITY_ROLE = keccak256("COMMUNITY");

    string private _name = "CVA Project";
    address public community;
    address private _defaultToken;
    bool private _isActive;
    IRahatClaim public RahatClaim;
    IRahatRegistry public RahatRegistry;
    IRahatCommunity public RahatCommunity;
    //IRahatDonor public RahatDonor;
    address public otpServerAddress;

    uint256 private _beneficiaryCount;
    EnumerableSet.AddressSet private beneficiaries;
    mapping(address => bool) private _isBeneficiary;
    mapping(address => uint256) public tokensReceived;
    mapping(address => mapping(address => uint)) claims; //benAddress=>tokenAddress=>amount;
    mapping(address => mapping(address => uint)) tokenRequestIds; //vendorAddress=>benAddress=>requestId;

    modifier onlyCommunityManager() {
        require(hasRole(COMMUNITY_ROLE, msg.sender), "not a community");
        _;
    }
    modifier onlyDonor() {
        require(hasRole(DONOR_ROLE, msg.sender), "not a donor");
        _;
    }

    constructor(
        address defaultToken_,
        address _rahatClaim,
        address _otpServerAddress,
        address _community,
        address _admin
    ) {
        _setRoleAdmin(VENDOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(COMMUNITY_ROLE, _community);
        _defaultToken = defaultToken_;
        RahatClaim = IRahatClaim(_rahatClaim);
        otpServerAddress = _otpServerAddress;
        community = _community;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function defaultToken() public view returns (address) {
        return _defaultToken;
    }

    function isActive() public view returns (bool) {
        return _isActive;
    }

    function beneficiaryCount() public view returns (uint256) {
        return _beneficiaryCount;
    }

    function isBeneficiary(address _account) public view returns (bool) {
        return _isBeneficiary[_account];
    }

    function acceptToken(
        address _token,
        address _from,
        uint256 _amount
    ) public {
        _claimToken(_token, _from, _amount);
        _setupRole(DONOR_ROLE, _from);
        tokensReceived[_token] += _amount;
    }

    function addBeneficiary(address _account) public onlyCommunityManager {
        _isBeneficiary[_account] = true;
        beneficiaries.add(_account);
    }

    function addClaimToBeneficiary(address _address, uint _amount) public {
        require(_isBeneficiary[_address], "not beneficiary");
        claims[_address][_defaultToken] = _amount;
    }

    //***** Claim functions *********//
    function requestTokenFromBeneficiary(
        address _benAddress,
        uint _amount
    ) public returns (uint requestId) {
        requestId = requestTokenFromBeneficiary(
            _benAddress,
            _defaultToken,
            _amount,
            otpServerAddress
        );
    }

    function requestTokenFromBeneficiary(
        address _benAddress,
        address _tokenAddress,
        uint _amount,
        address _otpServerAddress
    ) public returns (uint requestId) {
        require(otpServerAddress != address(0), "invalid otp-server");
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
        _benTokenBalance -= _claim.amount;

        transferToken(
            _claim.tokenAddress,
            _claim.claimerAddress,
            _claim.amount
        );
    }

    function withdrawClaims(address _to, uint256 _amount) public {
        require(_isBeneficiary[msg.sender], "not a ben");
        require(
            claims[msg.sender][_defaultToken] >= _amount,
            "not enough token"
        );
        transferToken(_defaultToken, _to, _amount);
    }
}
