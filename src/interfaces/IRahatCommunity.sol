//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IRahatCommunity is IAccessControl {
    ///@dev Accept Tokens from Rahatdonor => send to projectContract => give approval to RahatCommunity to spend
    ///@dev Save the received token in a set.
    ///@dev Save the no. of tokens issued to track total tokens received
    ///@dev acceptToken to SpecificProject
    function acceptToken(
        address _token,
        address _from,
        uint256 _amount,
        address _projectAddress
    ) external returns (bool);

    ///@dev create a project from projectFactory
    ///@dev specify tokens project gonna use
    function addProject(
        address _projectFactoryAddress,
        address _tokenAddress
    ) external;

    ///@dev updateBeneficiaryAddress to project
    function registerBeneficiaryToProject(
        address _project,
        address _beneficiary
    ) external;

    function isAdmin(address _address) external pure returns (bool);
    function isVendor(address _address) external pure returns (bool);
}
