//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IOtpOracle {
    function createRequest(
        address _requester,
        bytes32 _requestTo,
        uint256 _amount,
        bytes memory _data
    ) external;

    function approveRequest(
        address _requester,
        bytes32 _requestTo,
        bytes32 _otpHash,
        uint256 _expiryDate
    ) external;

    function resolveRequest(
        address _requester,
        bytes32 _requestTo,
        string memory _otp
    ) external;
}
