//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "../interfaces/IOtpOracle.sol";

contract OtpOracle is IOtpOracle {
    event RequestCreated(
        address indexed requester,
        bytes32 indexed requestedTo,
        uint256 amount,
        bytes data
    );
    event RequestApproved(
        address indexed requester,
        bytes32 indexed requestedTo,
        uint256 amount
    );
    event RequestResolved(
        address indexed requester,
        bytes32 indexed requestedTo
    );

    struct otpMetadata {
        bytes32 otpHash;
        uint256 expiryDate;
        bool isVerified;
        uint256 amount;
        bytes data;
    }

    mapping(address => mapping(bytes32 => otpMetadata))
        public recentOtpRequests;

    // create OTP request
    function createRequest(
        address _requester,
        bytes32 _requestTo,
        uint256 _amount,
        bytes memory _data
    ) public {
        otpMetadata storage recentOtpRequest = recentOtpRequests[_requester][
            _requestTo
        ];
        recentOtpRequest.amount = _amount;
        recentOtpRequest.data = _data;
        recentOtpRequest.expiryDate = block.timestamp;

        (bool success, ) = msg.sender.call(_data);
        require(success, "mint failed");
        emit RequestCreated(_requester, _requestTo, _amount, _data);
    }

    function approveRequest(
        address _requester,
        bytes32 _requestTo,
        bytes32 _otpHash,
        uint256 _expiryDate
    ) public {
        otpMetadata storage recentOtpRequest = recentOtpRequests[_requester][
            _requestTo
        ];
        recentOtpRequest.otpHash = _otpHash;
        recentOtpRequest.isVerified = true;
        recentOtpRequest.expiryDate = _expiryDate;

        emit RequestApproved(_requester, _requestTo, recentOtpRequest.amount);
    }

    function resolveRequest(
        address _requester,
        bytes32 _requestTo,
        string memory _otp
    ) public {
        otpMetadata storage recentOtpRequest = recentOtpRequests[_requester][
            _requestTo
        ];
        require(
            keccak256(abi.encodePacked(_otp)) == recentOtpRequest.otpHash,
            "Otp not match"
        );
        recentOtpRequest.isVerified = false;
        recentOtpRequest.expiryDate = 0;
        recentOtpRequest.otpHash = bytes32(0);
        emit RequestResolved(_requester, _requestTo);
    }
}
