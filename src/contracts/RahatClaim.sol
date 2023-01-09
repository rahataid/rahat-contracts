//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;
import "../interfaces/IRahatClaim.sol";

contract RahatClaim is IRahatClaim {
    event ClaimCreated(uint indexed claimId);
    event OtpAddedToClaim(uint indexed claimId);
    event ClaimProcessed(uint indexed claimId);

    mapping(uint => Claim) public claims;
    uint public claimCount;

    function createClaim(
        address _claimerAddress, 
        address _claimeeAddress,
        address _otpServerAddress,
        address _tokenAddress, 
        uint _amount
    ) public returns(uint claimId) {
        claimId = claimCount;
        claims[claimId] = Claim({
            ownerAddress: msg.sender,
            claimerAddress : _claimerAddress,
            claimeeAddress : _claimeeAddress,
            otpServerAddress : _otpServerAddress,
            tokenAddress : _tokenAddress,
            amount : _amount,
            expiryDate : block.timestamp,
            otpHash : bytes32(0),
            isProcessed: false
        });
        claimCount += 1;
        emit ClaimCreated(claimId);
    }

    function addOtpToClaim(
        uint _claimId, 
        bytes32 _otpHash,
        uint256 _expiryDate
    ) public {
        Claim storage _claim = claims[_claimId];
        require(_claim.otpServerAddress==msg.sender, 'unauthorized otpServer');
        require(_claim.isProcessed == false, 'already processed');
        _claim.expiryDate = _expiryDate;
        _claim.otpHash = _otpHash;
        emit OtpAddedToClaim(_claimId);
    }

    function processClaim(uint _claimId, string memory _otp) public returns(Claim memory _claim) {
        _claim = claims[_claimId];
        require(_claim.ownerAddress==msg.sender, 'not owner');
        require(block.timestamp >= _claim.expiryDate, 'expired');
        require(_claim.isProcessed == false, 'already processed');
        bytes32 _otpHash = findHash(_otp);
        require(_claim.otpHash==_otpHash, 'invalid otp');
        
        _claim.isProcessed = true;
        emit ClaimProcessed(_claimId);
    }

    function findHash(string memory _data) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_data));
    }
}
