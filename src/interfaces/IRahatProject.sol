//SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IRahatProject {
    function name() external view returns (string memory);

    function defaultToken() external view returns (address);

    function isLocked() external view returns (bool);

    function addBeneficiary(address _account) external;

    // function isBeneficiary(address _account) external view returns (bool);

    //function acceptToken(address _tokenAddress) external;
}
