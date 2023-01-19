//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IOtpOracle1 {

    struct Request {
        address ownerAddress;
        address otpServerAddress;
        bytes data;
        uint expiryDate;
        bytes32 otpHash;
        bool isProcessed;
    }

    function createRequest(
        address _otpServerAddress,
        bytes memory _data
    ) external returns(uint requestId);

    function approveRequest(
        uint _requestId, 
        bytes32 _otpHash,
        uint256 _expiryDate
    ) external;

    function resolveRequest(uint _requestId) external returns(Request memory _request);
}
