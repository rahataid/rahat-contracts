//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

interface IRahatProject {
   function name() external view returns(string memory);
   function defaultToken() external view returns(address);
   function isActive() external view returns(bool);
   function beneficiaryCount() external view returns(uint);
}