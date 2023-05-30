const hre = require('hardhat');
const { ethers } = require('hardhat');

async function main() {
  [deployer, donor, admin, manager, vendor1, vendor2, otpServer1, beneficiary1, beneficiary2] =
    await ethers.getSigners();
  const RahatDonor = await ethers.getContractFactory('RahatDonor');
  let rahatDonor = await RahatDonor.deploy(donor.address);
  console.log(rahatDonor.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
