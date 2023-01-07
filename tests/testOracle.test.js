//const { ethers } = require("hardhat");
//const exceptions = require("./exceptions");
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe.only("------ Oracle Tests ------", function () {
  let testOracle;
  let otpOracle;

  before(async function () {
    const [deployer, tester] = await ethers.getSigners();
    const OtpOracle = await ethers.getContractFactory("OtpOracle");
    const TestOracle = await ethers.getContractFactory("TestOracle");

    otpOracle = await OtpOracle.deploy();
    testOracle = await TestOracle.deploy("Rahat", "RTH", otpOracle.address);
  });

  describe("Deployment", function () {
    it("Should deploy contract", async function () {
      expect(await testOracle.name()).to.equal("Rahat");
      expect(await testOracle.otpOracle()).to.equal(otpOracle.address);
      console.log("testOracle:", testOracle.address);
    });
  });

  describe("Otp Implementation", function () {
    it("Create Otp Request", async function () {
      const initSupply = await testOracle.totalSupply();
      console.log({ initSupply });
      const tx = await testOracle.createOtp("111", 10);
      const supply = await testOracle.totalSupply();
      console.log({ supply });
      console.log("testOracle:", testOracle.address);
    });
  });
});
