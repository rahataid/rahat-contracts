// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IRahatTokenTransferGateway.sol';

contract RahatTokenTransferGateway is IRahatTokenTransferGateway {
  function transferToken(address _to, uint256 _amount) external payable {
    require(msg.value > 0, 'Invalid amount');
    require(msg.value == _amount, '"Amount should match the sent value.');

    // Transfer the specified amount of tokens to the specified address
    payable(_to).transfer(msg.value);
    emit TokenTransfer(msg.sender, _to, _amount);
  }

  // Function to transfer tokens from one address to another
  function transferERC20Token(address _tokenAddress, address _to, uint256 _amount) external {
    // Create an instance of the ERC20 token contract
    IERC20 token = IERC20(_tokenAddress);

    // Transfer tokens from the sender's address to the specified address
    token.transferFrom(msg.sender, _to, _amount);

    emit TokenTransfer(msg.sender, _to, _amount);
  }
}
