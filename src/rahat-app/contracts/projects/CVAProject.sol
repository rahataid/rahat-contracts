//SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.20;


import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/ERC2771Forwarder.sol";
import './ICVAProject.sol';
import '../../libraries/AbstractProject.sol';
import '../../interfaces/IRahatClaim.sol';

contract CVAProject is AbstractProject, ICVAProject, ERC2771Context {
  using EnumerableSet for EnumerableSet.AddressSet;
  // #region ***** Events *********//
  event ClaimAssigned(address indexed beneficiary, uint amount);
  event ClaimAdjusted(address indexed beneficiary, int amount);
  event ClaimProcessed(
    address indexed beneficiary,
    address indexed vendor,
    address indexed token,
    uint amount
  );

  event OtpServerUpdated(address indexed);
  // #endregion

  // #region ***** Variables *********//
  bytes32 private constant VENDOR_ROLE = keccak256('VENDOR');
  bytes4 public constant IID_RAHAT_PROJECT = type(IRahatProject).interfaceId;
  address public override defaultToken;

  IRahatClaim public RahatClaim;
  address public override otpServerAddress;

  mapping(address => bool) public override isDonor;

  mapping(address => uint) public override beneficiaryClaims; //benAddress=>amount;

  mapping(address => mapping(address => uint)) public tokenRequestIds; //vendorAddress=>benAddress=>requestId;

  // #endregion

  // // #region ***** Modifiers *********//
  // modifier onlyCommunityAdmin() {
  //   require(RahatCommunity.isAdmin(msg.sender), 'not a community admin');
  //   _;
  // }

  // #endregion

  constructor(
    string memory _name,
    address _defaultToken,
    address _rahatClaim,
    address _otpServerAddress,
    address _forwarder
  ) AbstractProject(_name) ERC2771Context(address(_forwarder)) {
    defaultToken = _defaultToken;
    RahatClaim = IRahatClaim(_rahatClaim);
    otpServerAddress = _otpServerAddress;
  }

 

  // #region ***** Beneficiary Function *********//

  function addBeneficiary(address _address) public  {
    _addBeneficiary(_address);
  }

  function assignClaims(
    address _address,
    uint _claimAmount
  ) public{
    _addBeneficiary(_address);
    _assignClaims(_address, _claimAmount);
  }

  function removeBeneficiary(address _address) public  {
    _removeBeneficiary(_address);
    _assignClaims(_address, 0);
  }

  function _assignClaims(address _beneficiary, uint _amount) private {
    require(
      IERC20(defaultToken).balanceOf(address(this)) >= totalClaimsAssgined() + _amount,
      'not enough tokens'
    );

    uint _origClaimAmt = beneficiaryClaims[_beneficiary];

    beneficiaryClaims[_beneficiary] = _amount;
    emit ClaimAssigned(_beneficiary, _amount);
    int claimDiff = int(_amount - _origClaimAmt);
    if (claimDiff != 0) emit ClaimAdjusted(_beneficiary, int(_amount - _origClaimAmt));
  }

  function totalClaimsAssgined() public view returns (uint _totalClaims) {
    for (uint i = 0; i < _beneficiaries.length(); i++) {
      _totalClaims += beneficiaryClaims[_beneficiaries.at(i)];
    }
  }

  // #endregion

  // #region ***** Token Functions *********//
  function acceptToken(address _from, uint256 _amount) public  {
    isDonor[_from] = true;
    _acceptToken(defaultToken, _from, _amount);
  }

  function withdrawToken(address _token,address _withdrawAddress) public  {
    uint _surplus = IERC20(_token).balanceOf(address(this));
    _withdrawToken(_token, _surplus,_withdrawAddress);
  }

  // #region ***** Claim Process *********//
  function requestTokenFromBeneficiary(
    address _benAddress,
    uint _amount
  ) public returns (uint requestId) {
    requestId = requestTokenFromBeneficiary(_benAddress, _amount, otpServerAddress);
  }

  function requestTokenFromBeneficiary(
    address _benAddress,
    uint _amount,
    address _otpServerAddress
  ) public returns (uint requestId) {
    require(otpServerAddress != address(0), 'invalid otp-server');
    require(beneficiaryClaims[_benAddress] >= _amount, 'not enough balance');

    requestId = RahatClaim.createClaim(
      _msgSender(),
      _benAddress,
      _otpServerAddress,
      defaultToken,
      _amount
    );
    tokenRequestIds[_msgSender()][_benAddress] = requestId;
  }

  function processTokenRequest(address _benAddress, string memory _otp) public {
    IRahatClaim.Claim memory _claim = RahatClaim.processClaim(
      tokenRequestIds[_msgSender()][_benAddress],
      _otp
    );
    _transferTokenToClaimer(
      _claim.tokenAddress,
      _claim.claimeeAddress,
      _claim.claimerAddress,
      _claim.amount
    );
  }

  //use this for offline transactions
  function sendBeneficiaryTokenToVendor(
    address _benAddress,
    address _vendorAddress,
    uint _amount
  ) public  {
    require(otpServerAddress == msg.sender, 'unauthorized');
    _transferTokenToClaimer(defaultToken, _benAddress, _vendorAddress, _amount);
  }

  function _transferTokenToClaimer(
    address _tokenAddress,
    address _benAddress,
    address _vendorAddress,
    uint _amount
  ) private {
    require(beneficiaryClaims[_benAddress] >= _amount, 'not enough balace');
    beneficiaryClaims[_benAddress] -= _amount;
    require(IERC20(_tokenAddress).transfer(_vendorAddress, _amount), 'transfer failed');
    emit ClaimProcessed(_benAddress, _vendorAddress, _tokenAddress, _amount);
  }

  // #endregion

  // #region ***** Housekeeping *********//
  function updateOtpServer(address _address) public {
    require(_address != address(0), 'invalid address');
    require(_address != address(this), 'cannot be contract address');
    require(_address != address(otpServerAddress), 'no change');
    otpServerAddress = _address;
    emit OtpServerUpdated(_address);
  }

  // #endregion

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == IID_RAHAT_PROJECT;
  }

     ///region overrides

    /// @dev overriding the method to ERC2771Context
    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address sender)
    {
        sender = ERC2771Context._msgSender();
    }

    /// @dev overriding the method to ERC2771Context
    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes calldata)
    {
        return ERC2771Context._msgData();
    }

    function _contextSuffixLength()
        internal
        view
        override(Context, ERC2771Context)
        returns (uint256)
    {
        return ERC2771Context._contextSuffixLength();
    }
}
