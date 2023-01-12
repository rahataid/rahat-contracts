//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "../../interfaces/IRahatProject.sol";

interface ICVAProject is IRahatProject {
    ///@dev Accept Tokens from Rahatdonor by projectManager(communityManager)
    ///@dev Save the received token in a set.
    ///@dev Save the no. of tokens issued to track total tokens received
    function acceptToken(
        address _token,
        address _from,
        uint256 _amount
    ) external returns (bool);

    ///@dev Assign Token to beneficiary
    function addClaimToBeneficiary(address _address, uint _amount) external;

    ///@dev withdraw claims of beneficiary by beneficary
    function withdrawClaims(address _to, uint _amount) external;

    //***** Claim functions *********//
    ///@dev Request For tokens From Beneficay by vendor
    function requestTokenFromBeneficiary(
        address _benAddress,
        address _tokenAddress,
        uint _amount
    ) external returns (uint requestId);

    ///@dev Process token request to beneficiary by otp verfication
    function processTokenRequest(
        address _benAddress,
        string memory _otp
    ) external;
}
