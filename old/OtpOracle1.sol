//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IOtpOracle1.sol";

contract RahatRequest is IOtpOracle1 {
    event RequestCreated(address indexed sender, uint indexed requestId);
    event RequestApproved(uint indexed requestId);
    event RequestResolved(address indexed sender, uint indexed requestId);
    
    mapping(uint => Request) public requests;
    uint public requestCount;

    function createRequest(
        address _otpServerAddress,
        bytes memory _data
    ) public returns(uint requestId){
        requestId = requestCount;
        requests[requestId] = Request({
            ownerAddress: msg.sender,
            otpServerAddress : _otpServerAddress,
            data: _data,
            expiryDate : block.timestamp,
            otpHash : bytes32(0),
            isProcessed: false
        });
        requestCount += 1;
        emit RequestCreated(msg.sender, requestId);
    }

    function approveRequest(
        uint _requestId, 
        bytes32 _otpHash,
        uint256 _expiryDate
    ) public {
        Request storage _request = requests[_requestId];
        require(_request.otpServerAddress==msg.sender, 'unauthorized otpServer');
        require(_request.isProcessed == false, 'already processed');
        _request.expiryDate = _expiryDate;
        _request.otpHash = _otpHash;
        emit RequestApproved(_requestId);
    }

    function resolveRequest(uint _requestId) public returns(Request memory _request) {
        _request = requests[_requestId];
        require(_request.ownerAddress==msg.sender, 'not owner');
        require(block.timestamp >= _request.expiryDate, 'expired');
        require(_request.isProcessed == false, 'already processed');
        _request.isProcessed = true;
        emit RequestResolved(msg.sender, _requestId);
    }
}
