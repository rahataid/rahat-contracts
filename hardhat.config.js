/**
 * @type import('hardhat/config').HardhatUserConfig
 */

require('solidity-coverage');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-waffle');
require("@openzeppelin/hardhat-upgrades");

module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './src/contracts',
    tests: './tests',
    cache: './hardhat_build/cache',
    artifacts: './hardhat_build/artifacts',
  },
};
