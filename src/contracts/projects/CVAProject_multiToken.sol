//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICVAProject.sol";
import "../../interfaces/IRahatClaim.sol";
import "../../interfaces/IRahatCommunity.sol";

//mapping(address=>mapping(address=>uint256)) public claims;

contract CVAProject is ICVAProject {
    using EnumerableSet for EnumerableSet.AddressSet;

    string public override name;
    address public override defaultToken;
    bool public override isLocked;
    
    IRahatClaim public RahatClaim;
    IRahatCommunity public RahatCommunity;
    address public otpServerAddress;

    EnumerableSet.AddressSet private beneficiaries;
    mapping(address => bool) public isDonor;

    mapping(address => uint256) public tokensReceived;
    mapping(address => mapping(address => uint)) public claims; //benAddress=>tokenAddress=>amount;
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
        string memory _name
        address _defaultToken,
        address _rahatClaim,
        address _otpServerAddress,
        address _community,
    ) {
        name = _name;
        defaultToken = _defaultToken;
        RahatClaim = IRahatClaim(_rahatClaim);
        RahatCommunity = IRahatCommunity(_community);
        otpServerAddress = _otpServerAddress;
    }

    function lockProject() public {
        require(isDonor(msg.sender), 'not a donor');
        require(beneficiaries.length()>0, 'no beneficiary');
    }

    //***** Beneficiary functions *********//
    function beneficiaryCount() public view returns (uint256) {
        return beneficiaries.length();
    }

    function addBeneficiary(address _account) public onlyUnlocked onlyCommunityAdmin {
        beneficiaries.add(_account);
    }

    function removeBeneficiary(address _account) public onlyUnlocked onlyCommunityAdmin {
        beneficiaries.remove(_account);
    }

    function listBeneficiaries(uint start, uint limit) public view returns (address[] memory _addresses) {
        for(uint i=start;i<limit;i++){
            _addresses.push(beneficiaries.at(i));
        }
    }

    function _assignClaims(uint _amount) private {
        uint requiredBudget = beneficiaries.length() * _amount;
        require(IERC20(defaultToken).balanceOf(address(this)) >= requiredBudget, 'not enough tokens');
        
        for(uint i=0;i<beneficiaries.length();i++){
            claims[beneficiaries.at(i)][defaultToken] = _amount;
        }
    }

    //***** Token functions *********//
    function acceptToken(
        address _from,
        uint256 _amount
    ) public onlyCommunityAdmin {
        //require(IERC20(_token).allowance(_from, address(this))>0,'no allowance');
        IERC20(defaultToken).transferFrom(_from, address(this), _amount)
        isLocked=false;
        tokensReceived[defaultToken] += _amount;
    }

    function withdrawSurplusTokens(
        address _token
    ) public onlyCommunityAdmin {
        uint _surplus = IERC20(_token).balanceOf(address(this))-tokensReceived[_token];
        IERC20(_token).transfer(address(RahatCommunity), _surplus)
    }

    function addClaimToBeneficiary(address _address, uint _amount) public onlyUnlocked onlyCommunityAdmin {
        require(beneficiaries.contains(_address), "not beneficiary");
        claims[_address][_defaultToken] = _amount;
    }

    function sendTokenToVendor(address _address, uint256 _amount) public onlyUnlocked onlyCommunityAdmin {
        require(
            RahatCommunity.isVendor(_address),
            "Not a Vendor"
        );
        IERC20(_defaultToken).approve(_address, _amount);
    }

    //***** Claim functions *********//
    function requestTokenFromBeneficiary(
        address _benAddress,
        uint _amount
    ) public onlyLocked returns (uint requestId) {
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
    ) public onlyLocked returns (uint requestId) {
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
    ) public onlyLocked {
        IRahatClaim.Claim memory _claim = RahatClaim.processClaim(
            tokenRequestIds[msg.sender][_benAddress],
            _otp
        );
        uint _benTokenBalance = claims[_claim.claimeeAddress][
            _claim.tokenAddress
        ];
        require(_benTokenBalance >= _claim.amount, "not enough balace");

        _benTokenBalance -= _claim.amount;

        IERC20(_claim.tokenAddress).transfer(_claim.claimerAddress, _claim.amount)
    }
}
