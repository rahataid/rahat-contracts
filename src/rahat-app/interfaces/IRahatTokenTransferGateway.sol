// SPDX-License-Identifier: LGPL-3.0

pragma solidity ^0.8.17;

interface IRahatTokenTransferGateway {
  event TokenTransfer(address indexed from, address indexed to, uint256 amount);

  function transferToken(address _to, uint256 _amount) external payable;

  function transferERC20Token(address _token, address _to, uint256 _amount) external;
}
