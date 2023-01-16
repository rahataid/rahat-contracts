//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "./RahatToken.sol";
import "../libraries/AbstractTokenActions.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Donor contract to create tokens
/// @author Rumsan Associates
/// @notice You can use this contract to manage Rahat tokens and projects
/// @dev All function calls are only executed by contract owner
contract RahatDonor is AbstractTokenActions {
    using EnumerableSet for EnumerableSet.AddressSet;

    event TokenCreated(address indexed tokenAddress);

    EnumerableSet.AddressSet private tokens;

    /// @notice All the supply is allocated to this contract
    /// @dev deploys AidToken and Rahat contract by sending supply to this contract
    constructor(address _admin) {
        _addOwner(_admin);
    }

    //#region Token function
    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 decimals
    ) public OnlyOwner returns (address) {
        RahatToken _token = new RahatToken(
            _name,
            _symbol,
            address(this),
            decimals
        );
        address _tokenAddress = address(_token);
        tokens.add(_tokenAddress);
        emit TokenCreated(_tokenAddress);
        return _tokenAddress;
    }

    function mintToken(address _token, uint256 _amount) public OnlyOwner {
        RahatToken(_token).mint(address(this), _amount);
    }

    function mintTokenAndApprove(
        address _token,
        address _approveAddress,
        uint256 _amount
    ) public OnlyOwner {
        RahatToken token = RahatToken(_token);
        token.mint(address(this), _amount);
        token.approve(_approveAddress, _amount);
    }

    function addTokenOwner(
        address _token,
        address _ownerAddress
    ) public OnlyOwner {
        RahatToken(_token).addOwner(_ownerAddress);
    }

    //#endregion

    function listTokens() public view returns (address[] memory) {
        return tokens.values();
    }
}
