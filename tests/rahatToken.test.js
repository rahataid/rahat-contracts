const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("------ Rahat Token Tests ------", function () {
  let rahatToken;

  before(async function () {
    const [deployer, donor] = await ethers.getSigners();
    const RahatToken = await ethers.getContractFactory("RahatToken");

    rahatToken = await RahatToken.connect(deployer).deploy(
      "Rahat",
      "RTH",
      donor.address,
      0
    );
  });

  describe("Deployment", function () {
    it("Should deploy contract", async function () {
      expect(await rahatToken.name()).to.equal("Rahat");
      console.log("rahatToken:", rahatToken.address);
    });
  });
});
