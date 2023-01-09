//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IRahatRegistry {
    function id2Address(bytes32 _id) external view returns(address) ;
    function addId2AddressMap(bytes32 _id, address _address) external returns(bool);
    function exists(bytes32 _id) external view returns(bool);
}
