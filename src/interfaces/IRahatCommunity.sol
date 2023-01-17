//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRahatCommunity is IAccessControl {
    event ProjectRequested {
        address indexed requestor,
        address indexed project
    } 

    function isBeneficiary(address _address) external view returns (bool);

    function isAdmin(address _address) external view returns (bool);

    function isVendor(address _address) external view returns (bool);

    function projectExists(address _projectAddress) external view returns (bool);

    function addProject(address _projectAddress) external;

    function requestToAddProject(address _projectAddress) external;
}
