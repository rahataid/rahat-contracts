//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICVAProject.sol";
import "../../interfaces/IRahatClaim.sol";
import "../../interfaces/IRahatCommunity.sol";

contract CVAProject is ICVAProject {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public override name;
    address public override defaultToken;
    bool public override isLocked;
    bool private _isClaimed;

    IRahatClaim public RahatClaim;
    IRahatCommunity public RahatCommunity;
    address public otpServerAddress;

    EnumerableSet.AddressSet private beneficiaries;
    mapping(address => bool) public isDonor;

    uint public tokensReceived;
    mapping(address => uint) public claims; //benAddress=>amount;

    uint public totalVendorAllocation;
    mapping(address => uint) public vendorAllowance;
    mapping(address => uint) public vendorAllowancePending;

    mapping(address => mapping(address => uint)) public tokenRequestIds; //vendorAddress=>benAddress=>requestId;

    modifier onlyCommunityAdmin() {
        require(RahatCommunity.isAdmin(msg.sender), "not a community admin");
        _;
    }

    modifier onlyUnlocked() {
        require(!isLocked, "project locked");
        _;
    }

    modifier onlyLocked() {
        require(!isLocked, "project unlocked");
        _;
    }

    constructor(
        string memory _name,
        address _defaultToken,
        address _rahatClaim,
        address _otpServerAddress,
        address _community
    ) {
        name = _name;
        defaultToken = _defaultToken;
        RahatClaim = IRahatClaim(_rahatClaim);
        RahatCommunity = IRahatCommunity(_community);
        otpServerAddress = _otpServerAddress;
        RahatCommunity.requestToAddProject(address(this));
    }

    function lockProject(uint _amount) public onlyUnlocked {
        require(isDonor[msg.sender], "not a donor");
        require(tokensReceived > 0, "no tokens");
        require(beneficiaries.length() > 0, "no beneficiary");
        _assignClaims(_amount);
        isLocked = true;
    }

    function unlockProject() public onlyLocked {
        require(isDonor[msg.sender], "not a donor");
        require(!_isClaimed, "claim already started");
        isLocked = false;
    }

    //***** Beneficiary functions *********//
    function beneficiaryCount() public view returns (uint256) {
        return beneficiaries.length();
    }

    function addBeneficiary(
        address _address
    ) public onlyUnlocked onlyCommunityAdmin {
        require(RahatCommunity.isBeneficiary(_address), 'not valid ben');
        beneficiaries.add(_address);
    }

    function removeBeneficiary(
        address _address
    ) public onlyUnlocked onlyCommunityAdmin {
        beneficiaries.remove(_address);
    }

    function listBeneficiaries(
        uint start,
        uint limit
    ) public view returns (address[] memory _addresses) {
        for (uint i = 0; i < limit; i++) {
            _addresses[i] = (beneficiaries.at(start + i));
        }
    }

    function _assignClaims(uint _amount) private {
        uint requiredBudget = beneficiaries.length() * _amount;
        require(
            IERC20(defaultToken).balanceOf(address(this)) >= requiredBudget,
            "not enough tokens"
        );

        for (uint i = 0; i < beneficiaries.length(); i++) {
            claims[beneficiaries.at(i)] = _amount;
        }
    }

    //***** Token functions *********//
    function acceptToken(
        address _from,
        uint256 _amount
    ) public onlyUnlocked onlyCommunityAdmin {
        //event community project list;
        require(RahatCommunity.projectExists(address(this)), 'project not approved');

        IERC20(defaultToken).transferFrom(_from, address(this), _amount);
        tokensReceived += _amount;
    }

    function withdrawSurplusTokens(address _token) public onlyCommunityAdmin {
        uint _surplus = IERC20(_token).balanceOf(address(this));
        if (_token == defaultToken) _surplus -= tokensReceived;
        IERC20(_token).transfer(address(RahatCommunity), _surplus);
    }

    function addClaimToBeneficiary(
        address _address,
        uint _amount
    ) public onlyUnlocked onlyCommunityAdmin {
        require(beneficiaries.contains(_address), "not beneficiary");
        claims[_address] = _amount;
    }

    function allowanceToVendor(
        address _address,
        uint256 _amount
    ) public onlyUnlocked onlyCommunityAdmin {
        require(RahatCommunity.isVendor(_address), "Not a Vendor");
        require(tokensReceived >= _amount, "not enough balance");
        vendorAllowancePending[_address] = _amount;
    }

    function acceptAllowance(
        uint256 _amount
    ) public onlyUnlocked onlyCommunityAdmin {
        require(RahatCommunity.isVendor(msg.sender), "Not a Vendor");
        vendorAllowance[msg.sender] += _amount;
        totalVendorAllocation += _amount;
        vendorAllowancePending[msg.sender] -= _amount;

        require(
            tokensReceived >= totalVendorAllocation,
            "not enough available allocation"
        );
    }

    //***** Claim functions *********//
    function requestTokenFromBeneficiary(
        address _benAddress,
        uint _amount
    ) public onlyLocked returns (uint requestId) {
        requestId = requestTokenFromBeneficiary(
            _benAddress,
            _amount,
            otpServerAddress
        );
    }

    function requestTokenFromBeneficiary(
        address _benAddress,
        uint _amount,
        address _otpServerAddress
    ) public onlyLocked returns (uint requestId) {
        require(otpServerAddress != address(0), "invalid otp-server");
        require(claims[_benAddress] >= _amount, "not enough balance");
        require(
            vendorAllowance[msg.sender] >= _amount,
            "not enough vendor allowance"
        );
        _isClaimed = true;

        requestId = RahatClaim.createClaim(
            msg.sender,
            _benAddress,
            _otpServerAddress,
            defaultToken,
            _amount
        );
        tokenRequestIds[msg.sender][_benAddress] = requestId;
    }

    function processTokenRequest(
        address _benAddress,
        string memory _otp
    ) public onlyLocked {
        IRahatClaim.Claim memory _claim = RahatClaim.processClaim(
            tokenRequestIds[msg.sender][_benAddress],
            _otp
        );
        uint _benTokenBalance = claims[_claim.claimeeAddress];
        require(_benTokenBalance >= _claim.amount, "not enough balace");

        _benTokenBalance -= _claim.amount;
        vendorAllowance[_claim.claimerAddress] -= _claim.amount;

        IERC20(_claim.tokenAddress).transfer(
            _claim.claimerAddress,
            _claim.amount
        );
    }

    function updateOtpServerAddress(address _address) public onlyCommunityAdmin {
        otpServerAddress = _address;
    }
}
