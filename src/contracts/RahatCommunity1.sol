//SPDX-License-Identifier: LGPL-3.0

pragma solidity ^0.8.17;

import './RahatCommunity.sol';

contract RahatCommunity1 is RahatCommunity{

    function changeName(string memory _name) public OnlyAdmin {
        name = _name;
    }
}