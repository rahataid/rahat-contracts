/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('solidity-coverage');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');

module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 50,
      },
    },
  },
  paths: {
    sources: './src/contracts',
    tests: './tests',
    cache: './cache',
    artifacts: './artifacts',
  },
};
