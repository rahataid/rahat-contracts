// const { expect } = require('chai');
// const { ethers } = require('hardhat');

// describe('------ Rahat Token Tests ------', function () {
//   let rahatToken;

//   before(async function () {
//     const [deployer, donor] = await ethers.getSigners();
//     const RahatToken = await ethers.getContractFactory('RahatToken');

//     rahatToken = await RahatToken.connect(deployer).deploy('Rahat', 'RTH', donor.address, 0);
//   });

//   describe('Deployment', function () {
//     it('Should deploy contract with correct name', async function () {
//       expect(await rahatToken.name()).to.equal('Rahat');
//       console.log('rahatToken:', rahatToken.address);
//     });
//   });

//   describe('Token Details Verification', function () {
//     it('Should create a token with 0 decimals', async function () {
//       expect(0).to.equal(1);
//     });
//     it('Should have 0 supply initially', async function () {
//       expect(0).to.equal(1);
//     });
//   });

//   describe('Ownership management', function () {
//     it('Should create a token given owners', async function () {
//       expect(0).to.equal(1);
//     });
//     it('Should be able to add owners for token', async function () {
//       expect(0).to.equal(1);
//     });

//     it('Only owner should be able to mint token', async function () {
//       expect(0).to.equal(1);
//     });
//   });
// });
